class RestGear < StickShift::Model
  attr_accessor :uuid, :components
  include LegacyBrokerHelper
  
  def initialize(uuid, components)
    self.uuid = uuid
    self.components = components
  end
  
  def to_xml(options={})
    options[:tag_name] = "gear"
    super(options)
  end
end
