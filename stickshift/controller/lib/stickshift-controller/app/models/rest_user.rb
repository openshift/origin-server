class RestUser < StickShift::Model
  attr_accessor :login, :consumed_gears, :max_gears, :capabilities, :plan_id, :usage_account_id, :links
  
  def initialize(cloud_user, url, nolinks=false)
    self.login = cloud_user.login
    self.consumed_gears = cloud_user.consumed_gears
    self.max_gears = cloud_user.max_gears
    self.capabilities = cloud_user.capabilities
    self.plan_id = cloud_user.plan_id
    self.usage_account_id = cloud_user.usage_account_id
    @links = {
      "LIST_KEYS" => Link.new("Get SSH keys", "GET", URI::join(url, "user/keys")),
      "ADD_KEY" => Link.new("Add new SSH key", "POST", URI::join(url, "user/keys"), [
        Param.new("name", "string", "Name of the key"),
        Param.new("type", "string", "Type of Key", ["ssh-rsa", "ssh-dss"]),
        Param.new("content", "string", "The key portion of an rsa key (excluding ssh-rsa and comment)"),
      ])
    } unless nolinks
  end
  
  def to_xml(options={})
    options[:tag_name] = "user"
    super(options)
  end
end
