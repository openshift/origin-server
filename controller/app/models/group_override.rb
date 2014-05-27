#
# A group override dictates a rule about how a component (cartridge) is represented in
# an application.  An override includes one or more components and a set of limits
# (or no limit) on scaling.  A component may also have its own limits through a
# ComponentOverrideSpec to define how it scales indepently within a group.
#
# All of the overrides for an application are reduced to calculate the appropriate
# shape of an application (how cartridges are placed into group instances, and the
# number of gears in that instance).  An override is "implicit" if it is provided
# by a rule of the system and should not be persisted.
#
class GroupOverride
  attr_reader :components, :min_gears, :max_gears, :gear_size, :additional_filesystem_gb
  attr_accessor :instance

  def self.integer_range(op, limit, *args)
    if v = args.map{ |i| i == -1 ? Float::INFINITY : i }.compact.send(op)
      v = [v, limit].send(op) if limit
      v = -1 if v == Float::INFINITY
      v
    end
  end

  ##
  # Merge a set of group overrides into the minimal possible set
  # WARNING: Alters the overrides provided.
  #
  def self.reduce(overrides, limit_to=nil)
    by_path = {}
    overrides.each do |override|
      next if override.blank?
      found = nil
      override.components.each do |c|
        if previous = by_path[c.path]
          # skip overrides we've already merged
          next if previous.equal?(override) && previous.equal?(found)
          if found
            # this override is already covered - subsume the previous override
            found.merge(previous)
            by_path.each{ |k, v| by_path[k] = found if v == previous }
          else
            # this override should be associated with a previous override
            found = previous
            found.merge(override)
            by_path.each{ |k, v| by_path[k] = found if v == override }
          end
        else
          # subsequent overrides should merge into this one
          by_path[c.path] = found || override
        end
      end
    end

    if limit_to
      limit_to.inject([]) do |arr, i|
        if override = by_path[i.path]
          unless arr.include?(override)
            arr << override.only_on(limit_to)
          end
        end
        arr
      end
    else
      by_path.values.inject([]) do |arr, override|
        arr << override unless arr.any?{ |a| a.equal?(override) }
        arr
      end
    end
  end

  ##
  # Merge one set of group overrides into another, using only the target
  # overrides as valid destinations.
  #
  def self.reduce_to(targets, overrides)
    by_path = {}
    targets.each{ |o| o.components.each{ |c| (by_path[c.path] ||= []) << o } }
    overrides.each do |override|
      next if override.blank?
      override.components.each do |component|
        if existing = by_path[component.path]
          existing.each{ |e| e.merge_strict(override) }
        end
      end
    end
    targets
  end

  def self.remove_defaults_from(overrides, min_gears=nil, max_gears=nil, gear_size=nil, additional_filesystem_gb=nil)
    return [] if overrides.blank?
    overrides.reject(&:implicit?).map do |o|
      o.dup.reset(
        (o.min_gears unless min_gears == o.min_gears),
        (o.max_gears unless max_gears == o.max_gears),
        (o.gear_size unless gear_size == o.gear_size),
        (o.additional_filesystem_gb unless additional_filesystem_gb == o.additional_filesystem_gb)
      ).presence
    end.compact
  end

  ##
  # Creates a new GroupOverride representing the provided object.
  #
  def self.resolve_from(instances, other)
    case other
    when GroupOverride
      if other.components.all?{ |c| instances.include?(c) }
        other.dup
      end
    when Hash
      required_for(ComponentSpec.resolve_from(instances, other["components"]), other)
    end
  end

  def self.required_for(components, hash)
    return nil unless components.present?
    values = hash.values_at(*KEYS)
    if components.length > 1 || values.any?(&:present?) || components.any?{ |c| ComponentOverrideSpec === c && !c.default? }
      GroupOverride.new(components, *values)
    end
  end

  def self.for_instance(instance)
    override = new(instance.all_component_instances.map{ |i| ComponentSpec.for_instance(i) }, nil, nil, nil, nil)
    override.instance = instance
    override
  end

  def initialize(*args)
    apply(*args)
  end

  def empty?
    @min_gears.nil? && @max_gears.nil? && @gear_size.blank? && @additional_filesystem_gb.blank? &&
      (@components.blank? || (@components.all?{ |s| s.nil? || s.default? } && @components.length < 1))
  end

  def inspect
    prefix = "#<#{self.class}"
    parts = []
    instance_variables.each do |var|
      v = instance_variable_get(var)
      next if v.nil?
      parts << "#{var}=#{v.inspect}"
    end
    if parts.empty?
      "#{prefix}>"
    else
      "#{prefix} #{parts.join(' ')}>"
    end
  end

  def ==(other)
    return true if equal?(other)
    return false unless GroupOverride === other
    return false unless components == other.components
    [:min_gears, :max_gears, :gear_size, :additional_filesystem_gb].all? do |sym|
      send(sym) == other.send(sym)
    end
  end
  alias_method :eql?, :==

  def hash
    @hash ||= components.hash
  end

  def mongoize
    h = {"components" => components.map(&:mongoize)}
    h['min_gears'] = @min_gears if @min_gears
    h['max_gears'] = @max_gears if @max_gears
    h['gear_size'] = @gear_size if @gear_size
    h['additional_filesystem_gb'] = @additional_filesystem_gb if @additional_filesystem_gb
    h
  end

  def self.mongoize(object)
    object.mongoize
  end

  def self.demongoize(object)
    binding
    case object
    when Hash
      required_for((object["components"] || []).compact.map{ |c| ComponentOverrideSpec.demongoize(c) }, object)
    else
      object
    end
  end

  def self.evolve(object)
    object
  end

  def implicit?
    @implicit
  end

  def implicit
    @implicit = true
    self
  end

  def merge(other)
    return self unless GroupOverride === other
    changed = apply(other.components, other.min_gears, other.max_gears, other.gear_size, other.additional_filesystem_gb)
    @implicit = nil unless other.implicit? || !changed
    self
  end

  def merge_strict(other)
    return self unless GroupOverride === other
    changed = apply(other.components.select{ |i| components.include?(i) }, other.min_gears, other.max_gears, other.gear_size, other.additional_filesystem_gb)
    @implicit = nil unless other.implicit? || !changed
    self
  end

  def only_on(components)
    (@components ||= []).keep_if{ |c| components.include?(c) }
    self
  end

  def clear(key)
    @implicit = nil
    instance_variable_set("@#{key}", nil) if KEYS.include?(key.to_s)
  end

  def defaults(min_gears, max_gears, gear_size, additional_filesystem_gb)
    @min_gears ||= min_gears
    @max_gears ||= max_gears
    @gear_size ||= gear_size
    @additional_filesystem_gb ||= additional_filesystem_gb
    self
  end

  def dup
    d = self.class.new(components.map(&:dup), min_gears, max_gears, gear_size, additional_filesystem_gb)
    d.implicit if implicit?
    d
  end

  def reset(min_gears, max_gears, gear_size, additional_filesystem_gb)
    @implicit = nil
    @min_gears = (Integer(min_gears) rescue nil)
    @max_gears = (Integer(max_gears) rescue nil)
    @gear_size = gear_size.to_s.presence
    @additional_filesystem_gb = (Integer(additional_filesystem_gb) rescue nil)
    self
  end

  protected
    KEYS = ["min_gears", "max_gears", "gear_size", "additional_filesystem_gb"]

    def apply(components, min_gears=nil, max_gears=nil, gear_size=nil, additional_filesystem_gb=nil)
      altered = false
      @components ||= []
      if ::Array === components
        @hash = nil # reset hash code
        components.each do |c|
          next unless ComponentOverrideSpec === c || ComponentSpec === c
          matched = false
          @components.each_with_index do |existing, i|
            if existing === c
              matched = true
              @components[i] = existing.merge(c)
              altered ||= (ComponentOverrideSpec === c) # not 100% accurate
            end
          end
          unless matched
            altered = true
            @components << c
          end
        end
        @components.sort!
      end

      if (i = GroupOverride.integer_range(:max, 0, @min_gears, (Integer(min_gears) rescue nil))) != @min_gears
        altered ||= i != 1
        @min_gears = i
      end
      if (i = GroupOverride.integer_range(:min, nil, @max_gears, (Integer(max_gears) rescue nil))) != @max_gears
        altered ||= i != -1
        @max_gears = i
      end

      # probably should be moved earlier in the override resolution process
      if @gear_size && gear_size && @gear_size != gear_size
        raise OpenShift::UserException.new("Incompatible gear sizes: #{@gear_size} and #{gear_size} for components: #{(components || []).map(&:name).uniq.to_sentence} that will reside on the same gear.", 142)
      end
      if gear_size
        altered = true
        @gear_size = gear_size 
      end

      if (i = GroupOverride.integer_range(:max, 0, @additional_filesystem_gb, (Integer(additional_filesystem_gb) rescue nil))) != @additional_filesystem_gb
        altered ||= i != 0
        @additional_filesystem_gb = i
      end
      altered
    end
end