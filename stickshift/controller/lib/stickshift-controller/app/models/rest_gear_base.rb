class RestGearBase < StickShift::Model
  attr_accessor :uuid, :components, :git_url
  include LegacyBrokerHelper
  
  def self.instance(uuid, components, git_url, node_profile)
    case $requested_api_version
    when "2.0"
      RestGearV2.new(uuid, components, git_url, node_profile)
    else
      RestGearBase.new(uuid, components, git_url)      
    end
  end
  
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
