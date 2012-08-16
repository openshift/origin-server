class RestGearGroupResources < StickShift::Model
  attr_accessor :uuid, :storage
  include LegacyBrokerHelper
  
  def initialize(uuid, storage)
    self.uuid = uuid
    self.storage = storage
  end
  
  def to_xml(options={})
    options[:tag_name] = "resources"
    super(options)
  end
end
