# Class representing a {CloudUser} level ssh key. These keys are provided by the user
# and used for all ssh and git operations.
#
# @!attribute [r] cloud_user
#   @return [CloudUser] The user this key belongs to.
class UserSshKey < SshKey
  include Mongoid::Document
  embedded_in :cloud_user, class_name: CloudUser.name
end
