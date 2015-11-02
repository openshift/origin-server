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
  # Default valid SSH key types if Rails.configuration.openshift[:valid_ssh_key_types] is nil
  DEFAULT_VALID_SSH_KEY_TYPES = ['ssh-rsa', 'ssh-dss', 'ssh-rsa-cert-v01@openssh.com', 'ssh-dss-cert-v01@openssh.com',
                                 'ssh-rsa-cert-v00@openssh.com', 'ssh-dss-cert-v00@openssh.com',
                                 'krb5-principal']
  # Default minimum SSH key size (number of bits used to create the key)
  # - default to zero to preserve previous functionality
  DEFAULT_MINIMUM_SSH_KEY_SIZE = 0 unless defined? DEFAULT_MINIMUM_SSH_KEY_SIZE

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
    presence: {message: "Key content is not valid."},
    key_content: true

  validates_presence_of :content, :message => "Key content is required and cannot be blank."
  validates_format_of :content,
                      :with => /\A[A-Za-z0-9\+\/=]+\z/,
                      :message => 'Invalid key content.',
                      :if => :is_ssh?
  validates_format_of :content,
                      :with => /\A[^#\r\n][^\r\n]*\z/,
                      :message => 'Invalid key content.',
                      :if => :is_kerberos?

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
  def self.get_valid_ssh_key_types
    Rails.configuration.openshift[:valid_ssh_key_types] || DEFAULT_VALID_SSH_KEY_TYPES
  end

  ##
  # Returns minimum SSH key size (number of bits used to create the key)
  def self.get_minimum_ssh_key_size(ssh_key_type)
    Rails.application.config.openshift[:minimum_ssh_key_size][ssh_key_type] rescue DEFAULT_MINIMUM_SSH_KEY_SIZE
  end

  # This method should be overridden in the subclasses, if required
  def to_obj(args={})
    self.name = args["name"] if args["name"]
    self.type = args["type"] if args["type"]
    self.content = args["content"] if args["content"]
    self
  end

  def is_ssh?
    type != 'krb5-principal'
  end

  def is_kerberos?
    type == 'krb5-principal'
  end

end
