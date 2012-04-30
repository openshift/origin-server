class RestGear < StickShift::Model
  attr_accessor :uuid, :components, :git_url
  include LegacyBrokerHelper
  
  def initialize(uuid, components, git_url)
    self.uuid = uuid
    self.components = components
    self.git_url = git_url
  end
  
  def to_xml(options={})
    options[:tag_name] = "gear"
    super(options)
  end
end
