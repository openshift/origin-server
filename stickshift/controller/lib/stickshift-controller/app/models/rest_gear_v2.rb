class RestGearV2 < RestGearBase
  attr_accessor :profile
  include LegacyBrokerHelper
  
  def initialize(uuid, components, git_url, node_profile)
    super(uuid, components, git_url)
    self.profile = node_profile
  end
  
  def to_xml(options={})
    options[:tag_name] = "gear"
    super(options)
  end
end
