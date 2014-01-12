class ComponentSpec
  attr_reader :path, :name, :id

  def initialize(name, id, cartridge_name, cartridge=nil, application=nil, component=nil)
    # minimum required attributes
    @name = name
    @id = id

    # reusable references to real objects
    @cartridge_name = name if name
    @cartridge = cartridge if cartridge
    @application = application if application
    @component = component if component

    @path = "#{@id || cartridge.id}/#{@name}"
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

  def ==(other)
    path == other.path
  end

  def hash
    path.hash
  end
end