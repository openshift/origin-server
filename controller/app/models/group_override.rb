class GroupOverride
  attr_reader :components, :min_gears, :max_gears, :gear_size, :additional_filesystem_gb

  def self.integer_range(op, limit, *args)
    if v = args.map{ |i| i == -1 ? Float::INFINITY : i }.compact.send(op)
      v = [v, limit].send(op) if limit
      v = -1 if v == Float::INFINITY
      v
    end
  end

  def self.resolve_from(instances, hash)
    if components = ComponentSpec.resolve_from(instances, hash["components"]).presence
      values = hash.values_at("min_gears", "max_gears", "gear_size", "additional_filesystem_gb")
      if values.any?(&:present?) or components.length > 1
        GroupOverride.new(components, *values)
      end
    end
  end

  def self.included_in?(overrides, override)
    overrides.any? do |o|
      next true if o == override
      o.components == override.components
    end
  end

  def initialize(*args)
    apply(*args)
  end

  def merge(other)
    return self unless GroupOverride === other
    apply(other.components, other.min_gears, other.max_gears, other.gear_size, other.additional_filesystem_gb)
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

  protected
    def apply(components, min_gears=nil, max_gears=nil, gear_size=nil, additional_filesystem_gb=nil)
      @components ||= []
      if Array === components
        components.each do |c|
          next unless ComponentOverrideSpec === c || ComponentSpec === c
          matched = false
          @components.each_with_index do |existing, i|
            if existing == c
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