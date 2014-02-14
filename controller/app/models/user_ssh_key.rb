# Class representing a {CloudUser} level ssh key. These keys are provided by the user
# and used for all ssh and git operations.
#
# @!attribute [r] cloud_user
#   @return [CloudUser] The user this key belongs to.
class UserSshKey < SshKey
  include Mongoid::Document
  embedded_in :cloud_user, class_name: CloudUser.name

  def to_obj(args={}, cloud_user)
    self.name = args["name"] if args["name"]
    self.type = args["type"] if args["type"]
    self.content = args["content"] if args["content"]
    self.cloud_user = cloud_user
    self
  end
end
