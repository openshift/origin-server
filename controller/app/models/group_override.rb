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
      override.components.each do |c|
        if previous = by_path[c.path]
          # skip overrides we've already merged
          next if previous.eql?(override)
          previous.merge(override)
          # some components may be new, ensure they are mapping to the located item
          previous.components.each{ |pc| by_path[pc.path] = previous }
        else
          # register this component to this override for further iteration
          by_path[c.path] = override
        end
      end
    end

    if limit_to
      limit_to.inject([]) do |arr, i|
        if override = by_path[i.path]
          arr << override unless arr.include?(override)
        end
        arr
      end
    else
      by_path.values.inject([]) do |arr, override|
        arr << override unless arr.any?{ |a| a.equal?(override) }
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
      override.components.each do |component|
        if existing = by_path[component.path]
          existing.each{ |e| e.merge_strict(override) }
        end
      end
    end
    targets
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
    if components.length > 1 || values.any?(&:present?)
      GroupOverride.new(components, *values)
    end
  end

  def self.for_instance(instance)
    override = new(instance.all_component_instances.map{ |i| ComponentSpec.for_instance(i) }, nil, nil, instance.gear_size, instance.addtl_fs_gb)
    override.instance = instance
    override
  end

  def initialize(*args)
    apply(*args)
  end

  def merge(other)
    return self unless GroupOverride === other
    apply(other.components, other.min_gears, other.max_gears, other.gear_size, other.additional_filesystem_gb)
    self
  end

  def merge_strict(other)
    return self unless GroupOverride === other
    apply(components && other.components, other.min_gears, other.max_gears, other.gear_size, other.additional_filesystem_gb)
    self
  end

  def clear(key)
    instance_variable_set("@#{key}", nil) if KEYS.include?(key.to_s)
  end

  def defaults(min_gears, max_gears, gear_size, additional_filesystem_gb)
    @min_gears ||= min_gears
    @max_gears ||= max_gears
    @gear_size ||= gear_size
    @additional_filesystem_gb ||= additional_filesystem_gb
    self
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

  def dup
    self.class.new(components.map(&:dup), min_gears, max_gears, gear_size, additional_filesystem_gb)
  end

  def mongoize
    h = {"components" => components.map(&:mongoize)}
    h['min_gears'] if min_gears
    h['max_gears'] if max_gears
    h['additional_filesystem_gb'] if additional_filesystem_gb
    h
  end

  def self.mongoize(object)
    object.mongoize
  end

  def self.demongoize(object)
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

  protected
    KEYS = ["min_gears", "max_gears", "gear_size", "additional_filesystem_gb"]

    def apply(components, min_gears=nil, max_gears=nil, gear_size=nil, additional_filesystem_gb=nil)
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
            end
          end
          @components << c unless matched
        end
      end

      @min_gears = GroupOverride.integer_range(:max, 1, @min_gears, (Integer(min_gears) rescue nil))
      @max_gears = GroupOverride.integer_range(:min, nil, @max_gears, (Integer(max_gears) rescue nil))

      # probably should be moved earlier in the override resolution process
      if @gear_size && gear_size && @gear_size != gear_size
        raise OpenShift::UserException.new("Incompatible gear sizes: #{@gear_size} and #{gear_size} for components: #{(components || []).map(&:name).uniq.to_sentence} that will reside on the same gear.", 142)
      end
      @gear_size = gear_size if gear_size

      @additional_filesystem_gb = GroupOverride.integer_range(:max, 0, @additional_filesystem_gb, (Integer(additional_filesystem_gb) rescue nil))
    end
end