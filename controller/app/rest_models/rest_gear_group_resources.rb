class RestGearGroupResources < OpenShift::Model
  attr_accessor :uuid, :storage
  
  def initialize(uuid, storage)
    self.uuid = uuid
    self.storage = storage
  end
  
  def to_xml(options={})
    options[:tag_name] = "resources"
    super(options)
  end
end
