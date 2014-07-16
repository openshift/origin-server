##
# @api REST
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
#     <plan-state nil="true"/>
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
# @!attribute [r] plan_state
#   @return [String] Plan State
# @!attribute [r] usage_account_id
#   @return [String] Account ID
class RestUser < OpenShift::Model
  attr_accessor :id, :login, :email, :consumed_gears, :capabilities, :plan_id, :plan_state, :plan_expiration_date, :plan_quantity, :usage_account_id, :links, :max_gears, :max_domains, :created_at, :usage_rates, :currency_cd, :max_teams

  def initialize(cloud_user, url, nolinks=false)
    [:id, :login, :email, :consumed_gears, :plan_id, :plan_state, :plan_expiration_date, :plan_quantity, :usage_account_id, :created_at].each{ |sym| self.send("#{sym}=", cloud_user.send(sym)) }

    self.capabilities = cloud_user.capabilities.serializable_hash
    self.usage_rates = cloud_user.usage_rates
    self.currency_cd = cloud_user.currency_cd
    self.max_gears = cloud_user.max_gears
    self.max_domains = cloud_user.max_domains
    self.max_teams = cloud_user.max_teams
    self.capabilities.delete("max_gears")
    self.capabilities.delete("max_domains")
    self.capabilities.delete("max_teams")

    if self.capabilities["max_tracked_addtl_storage_per_gear"] or self.capabilities["max_untracked_addtl_storage_per_gear"]
      tracked_storage = (self.capabilities["max_tracked_addtl_storage_per_gear"] || 0)
      untracked_storage = (self.capabilities["max_untracked_addtl_storage_per_gear"] || 0)
      self.capabilities["max_storage_per_gear"] = tracked_storage + untracked_storage
      self.capabilities.delete("max_tracked_addtl_storage_per_gear")
      self.capabilities.delete("max_untracked_addtl_storage_per_gear")
    end

    unless nolinks
      @links = {
        "ADD_KEY" => Link.new("Add new SSH key", "POST", URI::join(url, "user/keys"), [
          Param.new("name", "string", "Name of the key"),
          Param.new("type", "string", "Type of Key", SshKey.get_valid_ssh_key_types),
          Param.new("content", "string", "The key portion of an ssh key (excluding key type and comment)"),
        ]),
        "LIST_KEYS" => Link.new("List SSH keys", "GET", URI::join(url, "user/keys")),
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
