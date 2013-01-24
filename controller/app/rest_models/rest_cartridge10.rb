class RestCartridge10 < OpenShift::Model
  attr_accessor :type, :name, :properties, :status_messages

  def initialize(cart)
    self.name = cart.name
    self.type = "standalone"
    self.type = "embedded" if cart.categories.include? "embedded"
    self.status_messages = nil
    self.properties = {}
  end

  def to_xml(options={})
    options[:tag_name] = "cartridge"
    super(options)
  end
end