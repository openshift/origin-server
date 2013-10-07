##
# @api model
# Abstract class representing an SSH key. Used by {UserSshKey}, {ApplicationSshKey}, and {SystemSshKey}
# @!attribute [r] name
#   @return [String] Name of the ssh key. Must be unique for the user.
# @!attribute [r] type
#   @return [String] Type of the ssh key. Must be "ssh-rsa" or "ssh-dsa".
# @!attribute [r] content
#   @return [String] SSH key content
class SshKey
  include Mongoid::Document
  include AccessControlled

  # This is the current regex for validations for new ssh keys 
  KEY_NAME_REGEX = /\A[\w\.\-@+]+\z/
  def self.check_name!(name)
    if name.blank? or name !~ KEY_NAME_REGEX
      raise Mongoid::Errors::DocumentNotFound.new(self, nil, [name]) 
    end
    name
  end

  # Maximum length of valid SSH key name
  KEY_NAME_MAX_LENGTH = 256 unless defined? KEY_NAME_MAX_LENGTH
  # Minimum length of valid SSH key name  
  KEY_NAME_MIN_LENGTH = 1 unless defined? KEY_NAME_MIN_LENGTH
  # List of valid SSH key types  
  VALID_SSH_KEY_TYPES = ['ssh-rsa', 'ssh-dss', 'ssh-rsa-cert-v01@openssh.com', 'ssh-dss-cert-v01@openssh.com',
                         'ssh-rsa-cert-v00@openssh.com', 'ssh-dss-cert-v00@openssh.com']

  field :name, type: String
  field :type, type: String, default: "ssh-rsa"
  field :content, type: String

  validates :name,
    presence: {message: "Key name is required and cannot be blank."},
    format:   {with: KEY_NAME_REGEX, message: "Invalid key name. Name can only contain alphanumeric characters, underscores, dashes, dots, as well as @ and + symbols."},
    length:   {maximum: KEY_NAME_MAX_LENGTH, minimum: KEY_NAME_MIN_LENGTH, message: "Must be a minimum of #{KEY_NAME_MIN_LENGTH} and maximum of #{KEY_NAME_MAX_LENGTH} characters."}

  validates :type,
    presence: {message: "Key type is required and cannot be blank."},
    key_type: true

  validates :content,
    presence: {message:  "Key content is required and cannot be blank."},
    format:   {with: /\A[A-Za-z0-9\+\/=]+\z/, message: "Invalid key content."}
    
  validate :does_not_start_with_dot

  ##
  # Returns error codes associated with validation failures
  # @return [Integer] error codes:
  # * 117: Key name is invalid or blank
  # * 116: Key type is invalid
  # * 108: Key content is invalid
  def self.validation_map
    {name: 117, type: 116, content: 108}
  end
  
  def does_not_start_with_dot
    errors.add(:name, "Invalid key name. Name cannot start with \".\"") unless self.name !~ /^\./
  end

  ##
  # Returns list of valid SSH key types
  # @see SshKey::VALID_SSH_KEY_TYPES
  def self.get_valid_ssh_key_types()
    return VALID_SSH_KEY_TYPES
  end

  # This method should be overridden in the subclasses, if required
  def to_obj(args={})
    self.name = args["name"] if args["name"]
    self.type = args["type"] if args["type"]
    self.content = args["content"] if args["content"]
    self
  end

  # This method should be overridden in the subclasses, if required
  def to_key_hash()
    key_hash = {}
    key_hash["name"] = self.name
    key_hash["type"] = self.type
    key_hash["content"] = self.content
    key_hash["_type"] = self.class.to_s
    key_hash
  end
end
