##
# @api REST
# @version 1.0
# Describes a User
#
# Example:
#   ```
#   <user>
#     <login>admin</login>
#     <consumed-gears>4</consumed-gears>
#     <max-gears>100</max-gears>
#     <capabilities>
#       <subaccounts>false</subaccounts>
#       <gear-sizes>
#         <gear-size>small</gear-size>
#       </gear-sizes>
#     </capabilities>
#     <plan-id nil="true"/>
#     <usage-account-id nil="true"/>
#     <links>
#     ...
#     </links>
#   </user>
#   ```
#
# @!attribute [r] login
#   @return [String] The login name of the user
# @!attribute [r] consumed_gears
#   @return [Integer] Number of gears currently being used in applications
# @!attribute [r] max_gears
#   @return [Integer] Maximum number of gears available to the user
# @!attribute [r] capabilities
#   @return [Hash] Map of user capabilities
# @!attribute [r] plan_id
#   @return [String] Plan ID
# @!attribute [r] usage_account_id
#   @return [String] Account ID
class RestUser10 < OpenShift::Model
  attr_accessor :login, :consumed_gears, :max_gears, :capabilities, :plan_id, :usage_account_id, :links

  def initialize(cloud_user, url, nolinks=false)
    self.login = cloud_user.login
    self.consumed_gears = cloud_user.consumed_gears

    self.capabilities = cloud_user.capabilities.serializable_hash
    self.max_gears = self.capabilities["max_gears"]
    self.capabilities.delete("max_gears")

    self.plan_id = cloud_user.plan_id
    self.usage_account_id = cloud_user.usage_account_id

    unless nolinks
      @links = {
        "LIST_KEYS" => Link.new("Get SSH keys", "GET", URI::join(url, "user/keys")),
        "ADD_KEY" => Link.new("Add new SSH key", "POST", URI::join(url, "user/keys"), [
          Param.new("name", "string", "Name of the key"),
          Param.new("type", "string", "Type of Key", SshKey.get_valid_ssh_key_types),
          Param.new("content", "string", "The key portion of an rsa key (excluding ssh-rsa and comment)"),
        ]),
      }
      @links["DELETE_USER"] = Link.new("Delete user. Only applicable for subaccount users.", "DELETE", URI::join(url, "user"), nil, [
        OptionalParam.new("force", "boolean", "Force delete user. i.e. delete any domains and applications under this user", [true, false], false)
      ]) if cloud_user.parent_user_id
    end
  end

  def to_xml(options={})
    options[:tag_name] = "user"
    super(options)
  end
end
