class ComponentSpec
  attr_reader :path, :name, :id, :cartridge_name
  attr_writer :cartridge, :component, :application

  def self.for_model(component, cartridge, application=nil)
    spec = new(component.name, cartridge.id)
    spec.component = component
    spec.cartridge = cartridge
    spec.application = application
    spec
  end

  def self.for_instance(component_instance, application=nil)
    cart = component_instance.cartridge
    new(component_instance.component_name, cart.id, component_instance.cartridge.name, cart, application, nil)
  end

  # Resolve a list of component specs to valid component instances
  def self.resolve_from(instances, specs)
    return [] unless specs
    specs.map do |spec|
      case spec
      when ComponentSpec
        instances.find{ |i| i == spec }
      when Hash
        base = instances.find{ |i| i === spec }
        ComponentOverrideSpec.required_for(spec, base)
      when String
        instances.find{ |i| i === spec }
      else
        next
      end or next
    end.tap{ |a| a.compact! }
  end

  def initialize(name, id)
    @name = name
    @id = id
    @path = "#{@id}/#{@name}"
  end

  def cartridge
    @cartridge ||= CartridgeCache.find_cartridge_by_id(@id, @application) or
      raise OpenShift::UserException.new(
        if @application
          "The cartridge #{@id} is referenced in the application #{@application.name} but cannot be located."
        else
          "The cartridge #{@id} is cannot be located."
        end
      )
  end

  def component
    @component ||= cartridge.get_component(@name)
  end

  def profile
    @profile ||= cartridge.profile_for_feature(@name)
  end

  def ==(other)
    return true if equal?(other)
    return false unless other.respond_to?(:path)
    @path == other.path
  end

  def hash
    path.hash
  end

  ##
  # A ComponentSpec is equivalent to another spec with another path, a hash that
  # matches "cart" or "cart_id" and "name", or a string that matches a component
  # in the cartridge represented by this spec.
  #
  def ===(other)
    return true if self.==(other)
    case other
    when Hash
      return false unless @name == other['name']
      return true if @id == other['cart_id']
      return true if cartridge.name == other['cart']
      false
    when String
      return true if @name == other
      cart = cartridge
      if p = cart.profile_for_feature(other)
        # this is the cartridge because we found a profile matching the feature, just double
        # check on the component if this was an auto-generated component then we are good to
        # choose this ci
        return true if p.get_component(other).generated rescue nil
      end
      # This resolves cartridge contributed group-overrides for place, but is probably too
      # underspecified. Lookups of group override specs should be done by feature or type,
      # but probably not category.
      valid ||= cart.features.include?(other) || cart.categories.include?(other)
    end
  end

  def to_hash(*only)
    {"comp" => @name, "cart_id" => @id}
  end

  def merge(other)
    return other if ComponentOverrideSpec === other
    self
  end

  def inspect
    prefix = "#<#{self.class}"
    parts = inspect_parts
    if parts.empty?
      "#{prefix}>"
    else
      "#{prefix} #{parts.join(' ')}>"
    end
  end

  def inspect_parts
    parts = []
    instance_variables.each do |var|
      v = instance_variable_get(var)
      next if v.nil?
      s =
        case v
        when OpenShift::Component, OpenShift::Cartridge, CartridgeType, Application
          "<#{v.name}>"
        when OpenShift::Profile
          "<set>"
        else
          v.inspect
        end
      parts << "#{var}=#{s}"
    end
    parts
  end
end

class ComponentOverrideSpec < SimpleDelegator
  attr_reader :min_gears, :max_gears, :multiplier

  def self.required_for(hash, spec)
    args = hash.values_at("min_gears", "max_gears", "multiplier")
    if args.any?(&:present?)
      new(spec, *args)
    else
      spec
    end
  end

  def initialize(spec, *args)
    super(spec)
    apply(*args)
  end

  def merge(other)
    return self if ComponentSpec === other
    apply(other.min_gears, other.max_gears, other.multiplier)
    self
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
        when OpenShift::Component, OpenShift::Cartridge, CartridgeType, Application
          "<#{v.name}>"
        when OpenShift::Profile
          "<set>"
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

  protected
    def apply(min_gears, max_gears=nil, multiplier=nil)
      @min_gears = GroupOverride.integer_range(:max, 1, @min_gears, (Integer(min_gears) rescue nil))
      @max_gears = GroupOverride.integer_range(:min, nil, @max_gears, (Integer(max_gears) rescue nil))
      @multiplier = GroupOverride.integer_range(:max, 1, @multiplier, (Integer(multiplier) rescue nil))
    end
end