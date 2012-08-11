class Domain
  NAMESPACE_MAX_LENGTH = 16 unless defined? NAMESPACE_MAX_LENGTH
  NAMESPACE_MIN_LENGTH = 1 unless defined? NAMESPACE_MIN_LENGTH
  
  include Mongoid::Document
  include Mongoid::Timestamps

  field :namespace, type: String
  field :env_vars, type: Array, default: []
  embeds_many :system_ssh_keys, class_name: SystemSshKey.name
  belongs_to :owner, class_name: CloudUser.name
  has_and_belongs_to_many :users, class_name: CloudUser.name, inverse_of: nil
  has_many :applications, class_name: Application.name
  embeds_many :pending_ops, class_name: PendingDomainOps.name  
  
  validates :namespace,
    presence: {message: "Namespace is required and cannot be blank."},
    format:   {with: /\A[A-Za-z0-9]+\z/, message: "Invalid namespace. Namespace must only contain alphanumeric characters."},
    length:   {maximum: NAMESPACE_MAX_LENGTH, minimum: NAMESPACE_MIN_LENGTH, message: "Must be a minimum of #{NAMESPACE_MIN_LENGTH} and maximum of #{NAMESPACE_MAX_LENGTH} characters."},
    blacklisted: {message: "Namespace is not allowed.  Please choose another."}
  def self.validation_map
    {:namespace => 106}
  end
end
