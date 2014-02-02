#
# A reference to a specific component within a cartridge.
#
class ComponentSpec
  attr_reader :path, :name, :id, :cartridge_name
  attr_writer :cartridge, :component, :application

  def self.for_model(component, cartridge, application=nil)
    spec = new(component.name, cartridge.name, cartridge.id)
    spec.component = component
    spec.cartridge = cartridge
    spec.application = application
    spec
  end

  def self.for_instance(instance, application=nil)
    cart = instance.cartridge
    spec = new(instance.component_name, cart.name, instance.cartridge_id || cart.id)
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

  def initialize(name, cartridge_name, id=nil)
    @name = name
    @cartridge_name = cartridge_name
    @id = id
    @path = "#{@cartridge_name}/#{@name}"
  end

  def cartridge(from=nil)
    @cartridge ||= begin
      cart = @application.cartridges(from).detect{ |c| (@id && c.id === @id) || c.name == @cartridge_name } if @application
      cart = CartridgeCache.find_cartridge_by_id(@id) if cart.nil? && @id
      cart = CartridgeCache.find_cartridge(@cartridge_name) if cart.nil?
      if cart.nil?
        raise OpenShift::UserException.new("The cartridge #{@cartridge_name} is referenced by the application #{@application.name} but cannot be located.") if @application
        raise OpenShift::UserException.new("The cartridge #{@cartridge_name} cannot be located.")
      end
      cart
    end
  end

  def component
    @component ||= cartridge.get_component(@name)
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

  def default?
    true
  end

  def <=>(other)
    path <=> other.path
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
      if p = cart.get_component(other)
        return true if p.generated
      end
      # This resolves cartridge contributed group-overrides for place, but is probably too
      # underspecified. Lookups of group override specs should be done by feature or type,
      # but probably not category.
      valid ||= cart.features.include?(other) || cart.categories.include?(other)
    else
      self.==(other)
    end
  end

  def version_equal?(other)
    if id && other.id
      id === other.id
    else
      true
    end
  end

  def merge(other)
    return other if ComponentOverrideSpec === other
    self
  end

  def reset(*args)
    self
  end

  def dup
    self
  end

  def to_hash
    h = {"comp" => @name, "cart" => @cartridge_name}
    h['cart_id'] = @id if @id
    h
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
      new(object['comp'], object['cart'], object['cart_id'])
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
        when OpenShift::Component, OpenShift::Cartridge, CartridgeInstance, CartridgeType, Application
          "<#{v.name}>"
        else
          v.inspect
        end
      parts << "#{var}=#{s}"
    end
    parts
  end
end
