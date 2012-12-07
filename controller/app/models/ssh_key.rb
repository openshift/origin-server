# Abstract class representing an SSH key. Used by {UserSshKey}, {ApplicationSshKey}, and {SystemSshKey}
# @!attribute [r] name
#   @return [String] Name of the ssh key. Must be unique for the user.
# @!attribute [r] type
#   @return [String] Type of the ssh key. Must be "ssh-rsa" or "ssh-dsa".
# @!attribute [r] content
#   @return [String] SSH key content
class SshKey
  include Mongoid::Document
  
  KEY_NAME_MAX_LENGTH = 256 unless defined? KEY_NAME_MAX_LENGTH
  KEY_NAME_MIN_LENGTH = 1 unless defined? KEY_NAME_MIN_LENGTH
  VALID_SSH_KEY_TYPES = ['ssh-rsa', 'ssh-dss', 'ecdsa-sha2-nistp256-cert-v01@openssh.com', 'ecdsa-sha2-nistp384-cert-v01@openssh.com',
                         'ecdsa-sha2-nistp521-cert-v01@openssh.com', 'ssh-rsa-cert-v01@openssh.com', 'ssh-dss-cert-v01@openssh.com',
                         'ssh-rsa-cert-v00@openssh.com', 'ssh-dss-cert-v00@openssh.com', 'ecdsa-sha2-nistp256', 'ecdsa-sha2-nistp384', 'ecdsa-sha2-nistp521']
  
  self.field :name, type: String
  self.field :type, type: String, default: "ssh-rsa"
  self.field :content, type: String
  
  validates :name, 
    presence: {message: "Key name is required and cannot be blank."},
    format:   {with: /\A[A-Za-z0-9\.\-]+\z/, message: "Invalid key name. Name must only contain alphanumeric characters."},
    length:   {maximum: KEY_NAME_MAX_LENGTH, minimum: KEY_NAME_MIN_LENGTH, message: "Must be a minimum of #{KEY_NAME_MIN_LENGTH} and maximum of #{KEY_NAME_MAX_LENGTH} characters."}
  
  validates :type, 
    presence: {message: "Key type is required and cannot be blank."},
    key_type: true
  
  validates :content, 
    presence: {message:  "Key content is required and cannot be blank."},
    format:   {with: /\A[A-Za-z0-9\+\/=]+\z/, message: "Invalid key content."}
  
  def self.validation_map
    {name: 117, type: 116, content: 108}
  end
  
  def self.get_valid_ssh_key_types()
    return VALID_SSH_KEY_TYPES
  end
end
