class ComponentSpec
  attr_reader :path, :name, :id, :cartridge_name
  attr_writer :cartridge, :component, :application

  def self.for_model(component, cartridge, application=nil)
    spec = new(component.name, cartridge.name)
    spec.component = component
    spec.cartridge = cartridge
    spec.application = application
    spec
  end

  def self.for_instance(instance, application=nil)
    cart = instance.cartridge
    spec = new(instance.component_name, cart.name)
    spec.cartridge = cart
    spec.application = application || instance.has_application? ? instance.application : nil
    spec
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
        ComponentOverrideSpec.required_for(base, spec)
      when String
        instances.find{ |i| i === spec }
      else
        next
      end or next
    end.tap{ |a| a.compact! }
  end

  def initialize(name, cartridge_name)
    @name = name
    @cartridge_name = cartridge_name
    @path = "#{@cartridge_name}/#{@name}"
  end

  def cartridge
    @cartridge ||= CartridgeCache.find_cartridge(@cartridge_name, @application) or
      raise OpenShift::UserException.new(
        if @application
          "The cartridge #{@cartridge_name} is referenced in the application #{@application.name} but cannot be located."
        else
          "The cartridge #{@cartridge_name} is cannot be located."
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
    return other.==(self) if ComponentOverrideSpec === other
    return false unless ComponentSpec === other
    @path == other.path
  end
  alias_method :eql?, :==

  def hash
    path.hash
  end

  ##
  # A ComponentSpec is equivalent to another spec with another path, a hash that
  # matches "cart" and "name", or a string that matches a component
  # in the cartridge represented by this spec.
  #
  def ===(other)
    return true if equal?(other)
    case other
    when Hash
      return false unless @name == other['comp']
      return true if @cartridge_name == other['cart']
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
    else
      self.==(other)
    end
  end

  def merge(other)
    return other if ComponentOverrideSpec === other
    self
  end

  def dup
    self
  end

  def to_hash
    {"comp" => @name, "cart" => @cartridge_name}
  end

  def mongoize
    to_hash
  end

  def self.mongoize(object)
    object.mongoize
  end

  def self.demongoize(object)
    case object
    when Hash
      new(object['comp'], object['cart'])
    else
      object
    end
  end

  def self.evolve(object)
    object
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
