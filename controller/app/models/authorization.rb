class Authorization
  include Mongoid::Document
  include Mongoid::Timestamps
  include AccessControlled

  belongs_to :user, class_name: CloudUser.name
  field :identity_id, :type => String

  # An unguessable secret
  field :token, :type => String
  # Seconds to token expiration
  field :expires_in, :type => Integer
  field :revoked_at, :type => DateTime
  field :note, :type => String
  field :scopes, :type => String, :default => lambda{ Scope.default }

  # Denormalized expiration, query only
  field :expires_at, :type => DateTime
  before_save lambda{ set_created_at; self.expires_at = created_at + expires_in.seconds }

  # OAuth client that owns this token
  field :oauth_client_id, :type => String

  index({ token: 1 }, { unique: true })
  index({ user_id: 1 })

  create_indexes

  attr_accessible :note, :expires_in

  validates :token, :uniqueness => true
  validates :identity_id, :presence => true
  validates :note, length: {maximum: 4096}

  before_validation :generate_token, :associate_identity, :on => :create

  scope :for_owner, lambda { |user| where(:user_id => user.respond_to?(:to_key) ? user.id : user) }
  scope :matches_details, lambda { |note, scopes|
    q = queryable
    q = q.where(:note => note.to_s) if note
    q = q.where(:scopes => scopes.to_s) if scopes.present?
    q
  }
  scope :expired, lambda{ where(:expires_at.lt => DateTime.now) }
  scope :not_expired, lambda{ where(:expires_at.gt => DateTime.now, :revoked_at => nil) }

  def self.authenticate(token)
    with(consistency: :eventual).where(token: token).find_by
  rescue Mongoid::Errors::DocumentNotFound
    where(token: token).first
  end

  def self.revoke_all_for(application_id, resource_owner)
    delete_all_for(application_id, resource_owner)
  end

  def self.matching_token_for(user)#(application, resource_owner_or_id, scopes)
    user_id = user.respond_to?(:to_key) ? user.id : user
    token = last_authorized_token_for(user)#(application, resource_owner_id)
    token #if token && ScopeChecker.matches?(token.scopes, scopes)
  end

  def scopes
    self[:scopes]
  end
  def scopes_list
    Scope.list(scopes)
  end
  def scopes=(scope)
    self[:scopes] = scope && scope.is_a?(String) ? scope : scope.to_s || nil
  end

  # Maps to Doorkeeper::Models::Revokeable
  def revoke(clock = DateTime)
    update_attribute :revoked_at, clock.now
  end

  def revoked?
    revoked_at.present?
  end
  def accessible?
    !expired? && !revoked?
  end

  # Maps to Doorkeeper::Models::Expirable
  def expired?
    expires_in && (expires_in < 1 || Time.now > expired_time)
  end

  def expired_time
    created_at + expires_in.seconds
  end

  def expires_in_seconds
    return nil if expires_in.nil?
    expires = (created_at + expires_in.seconds) - Time.now
    expires_sec = expires.seconds.round(0)
    expires_sec > 0 ? expires_sec : 0  
  end
  #private :expired_time

  def self.last_authorized_token_for(application, resource_owner_id)
    where(:application_id => application.id,
          :resource_owner_id => resource_owner_id,
          :revoked_at => nil).
    order_by([:created_at, :desc]).
    limit(1).
    first
  end
  private_class_method :last_authorized_token_for

  private
    def generate_token
      self.token = SecureRandom.hex(32)
    end
    def collapse_scopes
      self.scopes = scopes.to_s unless scopes.is_a? String
    end
    def associate_identity
      self.identity_id = user.login
    end
end
