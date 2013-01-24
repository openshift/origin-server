class RestGear < OpenShift::Model
  attr_accessor :uuid, :components
  
  def initialize(uuid, components)
    self.uuid = uuid
    self.components = components
  end
  
  def to_xml(options={})
    options[:tag_name] = "gear"
    super(options)
  end
end
