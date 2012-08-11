class SshKey
  KEY_NAME_MAX_LENGTH = 256 unless defined? KEY_NAME_MAX_LENGTH
  KEY_NAME_MIN_LENGTH = 1 unless defined? KEY_NAME_MIN_LENGTH
  
  include Mongoid::Document
  embedded_in :cloud_user, class_name: CloudUser.name
  
  field :name, type: String
  field :type, type: String, default: "ssh-rsa"
  field :content, type: String
  
  validates :name, 
    presence: {message: "Key name is required and cannot be blank."},
    format:   {with: /\A[A-Za-z0-9]+\z/, message: "Invalid key name. Name must only contain alphanumeric characters."},
    length:   {maximum: KEY_NAME_MAX_LENGTH, minimum: KEY_NAME_MIN_LENGTH, message: "Must be a minimum of #{KEY_NAME_MIN_LENGTH} and maximum of #{KEY_NAME_MAX_LENGTH} characters."}
  
  validates :type, 
    presence: {message: "Key type is required and cannot be blank."},
    format:   {with: /\A(ssh-rsa|ssh-dss)\z/, message: "Invalid key type.  Valid types are ssh-rsa or ssh-dss."}
  
  validates :content, 
    presence: {message:  "Key content is required and cannot be blank."},
    format:   {with: /\A[A-Za-z0-9\+\/=]+\z/, message: "Invalid key content."}
  
  def self.validation_map
    {name: 117, type: 116, content: 108}
  end
end
