require 'delegate'

class ComponentOverrideSpec < SimpleDelegator
  attr_reader :min_gears, :max_gears, :multiplier

  def self.required_for(spec, hash)
    return nil if spec.nil?
    args = hash.values_at(*KEYS)
    if args.any?(&:present?)
      new(spec, *args)
    else
      spec
    end
  end

  def initialize(spec, *args)
    raise "First argument must be a ComponentSpec" unless ComponentSpec === spec
    super(spec)
    apply(*args)
  end

  def merge(other)
    return self if ComponentSpec === other
    apply(other.min_gears, other.max_gears, other.multiplier)
    self
  end

  def clear(key)
    instance_variable_set("@#{key}", nil) if KEYS.include?(key.to_s)
  end

  def ==(other)
    return true if equal?(other)
    case other
    when ComponentSpec
      other == __getobj__
    when ComponentOverrideSpec
      __getobj__ == other.__getobj__
    end
  end
  alias_method :eql?, :==

  def ===(other)
    case other
    when ComponentSpec
      other == __getobj__
    else
      self.==(other)
    end
  end

  def dup
    self.class.new(__getobj__, min_gears, max_gears, multiplier)
  end

  def to_s
    super.to_s
  end

  def inspect
    prefix = "#<#{self.class}"
    parts = inspect_parts
    instance_variables.each do |var|
      next if var == :@delegate_sd_obj
      v = instance_variable_get(var)
      next if v.nil?
      s =
        case v
        when OpenShift::Component, OpenShift::Cartridge, CartridgeInstance, CartridgeType, Application
          "<#{v.name}>"
        else
          v.inspect
        end
      parts << "#{var}=#{s}"
    end
    if parts.empty?
      "#{prefix}>"
    else
      "#{prefix} #{parts.join(' ')}>"
    end
  end

  def mongoize
    h = __getobj__.mongoize
    h["min_gears"] = min_gears if min_gears
    h["max_gears"] = max_gears if max_gears
    h["multiplier"] = multiplier if multiplier
    h
  end

  def self.mongoize(object)
    object.mongoize
  end

  def self.demongoize(object)
    case object
    when Hash
      required_for(ComponentSpec.demongoize(object), object)
    else
      object
    end
  end

  def self.evolve(object)
    object
  end

  def default?
    @min_gears.nil? && @max_gears.nil? && @multiplier.nil?
  end

  def reset(min_gears, max_gears, multiplier)
    @min_gears = (Integer(min_gears) rescue nil)
    @max_gears = (Integer(max_gears) rescue nil)
    @multiplier = (Integer(multiplier) rescue nil)
    self
  end

  protected
    KEYS = ["min_gears", "max_gears", "multiplier"]

    def apply(min_gears, max_gears=nil, multiplier=nil)
      @min_gears = GroupOverride.integer_range(:max, 1, @min_gears, (Integer(min_gears) rescue nil))
      @max_gears = GroupOverride.integer_range(:min, nil, @max_gears, (Integer(max_gears) rescue nil))
      @multiplier = GroupOverride.integer_range(:max, 0, @multiplier, (Integer(multiplier) rescue nil))
    end
end