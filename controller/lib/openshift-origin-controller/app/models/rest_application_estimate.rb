class RestApplicationEstimate < OpenShift::Model
  attr_accessor :components
  
  def initialize(components)
    self.components = components
  end
  
  def to_xml(options={})
    options[:tag_name] = "gear"
    super(options)
  end
end
