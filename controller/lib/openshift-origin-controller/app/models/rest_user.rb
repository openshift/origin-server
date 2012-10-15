class RestUser < OpenShift::Model
  attr_accessor :login, :consumed_gears, :max_gears, :capabilities, :plan_id, :usage_account_id, :links, :consumed_gear_sizes
  
  def initialize(cloud_user, url, nolinks=false)
    self.login = cloud_user.login
    self.consumed_gears = cloud_user.consumed_gears
    self.max_gears = cloud_user.max_gears
    self.capabilities = cloud_user.capabilities
    self.plan_id = cloud_user.plan_id
    self.usage_account_id = cloud_user.usage_account_id

    unless nolinks
      @links = {
        "LIST_KEYS" => Link.new("Get SSH keys", "GET", URI::join(url, "user/keys")),
        "ADD_KEY" => Link.new("Add new SSH key", "POST", URI::join(url, "user/keys"), [
          Param.new("name", "string", "Name of the key"),
          Param.new("type", "string", "Type of Key", Key::VALID_SSH_KEY_TYPES),
          Param.new("content", "string", "The key portion of an ssh key (excluding ssh type and comment)"),
        ])
      }
      @links["DELETE_USER"] = Link.new("Delete user. Only applicable for subaccount users.", "DELETE", URI::join(url, "user"), nil, [
        OptionalParam.new("force", "boolean", "Force delete user. i.e. delete any domains and applications under this user", [true, false], false)
      ]) if cloud_user.parent_user_login
    end

    consumed_map = {}
    if cloud_user.applications
      cloud_user.applications.each { |a|
        a.gears.each { |g|
          size = g.node_profile || Application.DEFAULT_NODE_PROFILE
          consumed_map[size] = 0 if not consumed_map.has_key? size
          consumed_map[size] = consumed_map[size] +1
        }
      }
    end
    self.consumed_gear_sizes = consumed_map
  end
  
  def to_xml(options={})
    options[:tag_name] = "user"
    super(options)
  end
end
