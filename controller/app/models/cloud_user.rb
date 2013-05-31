# Primary User model for the broker. It keeps track of plan details, capabilities and ssh-keys for the user.
# @!attribute [r] login
#   @return [String] Login name for the user.
# @!attribute [r] capabilities
#   @return [Hash] Hash representing the capabilities of the user. It is updated using the oo-admin-user-ctl scripts or when a plan changes.
# @!attribute [r] parent_user_id
#   @return [Moped::BSON::ObjectId] ID of the parent user object if this object represents a sub-account.
# @!attribute [rw] plan_id
# @!attribute [rw] pending_plan_id
# @!attribute [rw] pending_plan_uptime
# @!attribute [rw] usage_account_id
# @!attribute [rw] consumed_gears
#   @return [Integer] Number of gears that are being consumed by applications owned by this user
# @!attribute [r] ssh_keys
#   @return [Array[SshKey]] SSH keys used to access applications that the user has access to or owns
#     @see {#add_ssh_key}, {#remove_ssh_key}, and {#update_ssh_key}
# @!attribute [r] pending_ops
#   @return [Array[PendingUserOps]] List of {PendingUserOps} objects
class CloudUser
  include Mongoid::Document
  include Mongoid::Timestamps
  include UtilHelper
  alias_method :mongoid_save, :save

  DEFAULT_SSH_KEY_NAME = "default"

  field :login, type: String
  field :capabilities, type: Hash, default: ->{ default_capabilities }
  field :parent_user_id, type: Moped::BSON::ObjectId
  field :plan_id, type: String
  field :plan_state, type: String
  field :pending_plan_id, type: String
  field :pending_plan_uptime, type: Time
  field :plan_history, type: Array, default: []
  field :usage_account_id, type: String
  field :consumed_gears, type: Integer, default: 0
  embeds_many :ssh_keys, class_name: UserSshKey.name
  embeds_many :pending_ops, class_name: PendingUserOps.name
  # embeds_many :identities, class_name: Identity.name, cascade_callbacks: true
  has_many :domains, class_name: Domain.name, dependent: :restrict, :foreign_key => 'owner_id'
  has_many :authorizations, class_name: Authorization.name, dependent: :restrict

  validates :login, presence: true, login: true
  validates :capabilities, presence: true, capabilities: true

  scope :with_plan, any_of({:plan_id.ne => nil}, {:pending_plan_id.ne => nil}) 
  index({:login => 1}, {:unique => true})

  scope :with_identity_id, lambda{ |id| where(login: id) }
  scope :with_identity, lambda{ |provider, uid| with_identity_id(uid) }
  # Will become as follows when identities are present
  #
  #  index({:'identities._id' => 1}, {:unique => true})
  #  scope :with_identity_id, lambda{ |id| where(:'identities._id' => id) }
  #  scope :with_identity, lambda{ |provider, uid| with_identity_id(Identity.id_for(provider, uid)) }
  #  validate{ errors.add(:base, "CloudUser must have one or more identities") if identities.empty? }

  create_indexes

  # Returns a map of field to error code for validation failures.
  def self.validation_map
    {login: 107, capabilities: 107}
  end

  # Auth method can either be :login or :broker_auth. :login represents a normal 
  # authentication with user/pass. :broker_auth is used when the applciation needs 
  # to make a request to the broker on behalf of the user (eg: scale-up)
  #
  # This is a transient attribute and is not persisted
  attr_accessor :auth_method

  # Identity support will add the following:
  #
  # # This is a transient attribute and is not persisted
  # attr_accessor :current_identity
  # def current_identity!(provider, uid)
  #  self.current_identity = identities.select{ |i| i.provider == provider && i.uid == uid }.first
  # end

  # Convenience method to get the max_gears capability
  def max_gears
    get_capabilities["max_gears"]
  end
  def max_gears=(m)
    user_capabilities = get_capabilities
    user_capabilities["max_gears"] = m
    set_capabilities(user_capabilities)
  end

  def max_storage
    user_capabilities = get_capabilities
    max_untracked_storage = user_capabilities["max_untracked_addtl_storage_per_gear"] || 0
    max_tracked_storage = user_capabilities["max_tracked_addtl_storage_per_gear"] || 0
    (max_untracked_storage + max_tracked_storage)
  end

  def save(options = {})
    res = false
    notify = !self.persisted?
    notify_observers(:before_cloud_user_create) if notify
    begin
      begin
        res = mongoid_save(options)
        notify_observers(:cloud_user_create_success) if notify
      rescue Exception => e
        Rails.logger.debug e
        begin
          notify_observers(:cloud_user_create_error) if notify
        ensure
          raise
        end
      end
    ensure
      notify_observers(:after_cloud_user_create) if notify
    end
    res
  end

  #
  # Identity support will introduce a provider attribute that must be
  # passed to this method. Use the two argument form:
  #
  #   find_by_identity(nil, login)
  #
  # to locate a user.
  #
  def self.find_by_identity(*arguments)
    if arguments.length == 2
      with_identity(*arguments)
    else
      with_identity_id(arguments[0])
    end.find_by
  end

  #
  # Identity support will introduce a provider attribute that is used to 
  # identify the source of a particular login.  Until then, users are only 
  # identified by their login and provider is ignored.
  #
  def self.find_or_create_by_identity(provider, login, create_attributes={}, &block)
    login = login.to_s
    provider = provider.to_s if provider
    user = find_by_identity(nil, login)
    #identity = user.current_identity!(provider, login)
    yield user, login if block_given?
    user
  rescue Mongoid::Errors::DocumentNotFound
    user = new(create_attributes)
    #user.current_identity = user.identities.build(provider: provider, uid: login)
    #user.login = user.current_identity.id
    user.login = login
    begin
      user.with(safe: true).save
      Lock.create_lock(user)
      OpenShift::UserActionLog.action("CREATE_USER", true, "Creating user", 'USER' => user.id, 'LOGIN' => login, 'PROVIDER' => provider)
      user
    rescue Moped::Errors::OperationFailure
      user = find_by_identity(nil, login)
      raise unless user
      yield user, login if block_given?
      user
    end
  end

  # Used to add an ssh-key to the user. Use this instead of ssh_keys= so that the key can be propagated to the
  # domains/application that the user has access to.
  def add_ssh_key(key)
    if self.domains.count > 0
      pending_op = PendingUserOps.new(op_type: :add_ssh_key, arguments: key.attributes.dup, state: :init, on_domain_ids: self.domains.map{|d|d._id.to_s}, created_at: Time.new)
      CloudUser.where(_id: self.id).update_all({ "$push" => { pending_ops: pending_op.serializable_hash_with_timestamp , ssh_keys: key.serializable_hash }})
      self.with(consistency: :strong).reload
      self.run_jobs
    else
      #TODO shouldn't << always work???
      if self.ssh_keys.exists?
        self.ssh_keys << key
      else
        self.ssh_keys = [key]
      end
    end
  end
  
  # Used to update an ssh-key on the user. Use this instead of ssh_keys= so that the key update can be propagated to the
  # domains/application that the user has access to.
  def update_ssh_key(key)
    remove_ssh_key(key.name)
    add_ssh_key(key)
  end

  # Used to remove an ssh-key from the user. Use this instead of ssh_keys= so that the key removal can be propagated to the
  # domains/application that the user has access to.
  def remove_ssh_key(name)
    key = self.ssh_keys.find_by(name: name)
    if self.domains.count > 0
      pending_op = PendingUserOps.new(op_type: :delete_ssh_key, arguments: key.attributes.dup, state: :init, on_domain_ids: self.domains.map{|d|d._id.to_s}, created_at: Time.new)
      CloudUser.where(_id: self.id).update_all({ "$push" => { pending_ops: pending_op.serializable_hash_with_timestamp } , "$pull" => { ssh_keys: key.serializable_hash }})
      self.with(consistency: :strong).reload
      self.run_jobs      
    else
      key.delete
    end
  end

  def default_capabilities
    {
      "subaccounts" => false,
      "gear_sizes" => Rails.application.config.openshift[:default_gear_capabilities],
      "max_gears" => Rails.application.config.openshift[:default_max_gears],
    }
  end

  def inherited_capabilities
    @inherited_capabilities ||= begin
        if self.parent_user_id
          caps = CloudUser.find_by(_id: self.parent_user_id).get_capabilities
          caps.slice(*Array(caps['inherit_on_subaccounts']))
        end
      rescue Mongoid::Errors::DocumentNotFound
      end || {}
  end

  def get_capabilities
    self.capabilities.deep_dup.merge!(inherited_capabilities)
  end

  def set_capabilities(caps=nil)
    self.capabilities = caps.presence || default_capabilities
  end

  # Delete user and all its artifacts like domains, applications associated with the user 
  def force_delete
    # will need to read from the primary to make sure we get the latest data
    while Domain.with(consistency: :strong).where(owner: self).count > 0
      domain = Domain.with(consistency: :strong).where(owner: self).first
      while Application.with(consistency: :strong).where(domain: domain).count > 0
        app = Application.with(consistency: :strong).where(domain: domain).first
        app.destroy_app
      end
      domain.delete
    end
    
    # will need to reload from primary to ensure that mongoid doesn't validate based on its cache
    # and prevent us from deleting this user because of the :dependent :restrict clause
    self.with(consistency: :strong).reload
    self.delete
  end
 
  # Runs all jobs in :init phase and stops at the first failure.
  #
  # == Returns:
  # True on success or false on failure
  def run_jobs
    begin
      while self.pending_ops.where(state: :init).count > 0
        op = self.pending_ops.where(state: :init).first

        # store the op._id to load it later after a reload
        # this is required to prevent a reload from replacing it with another one based on position
        op_id = op._id

        # try to do an update on the pending_op state and continue ONLY if successful
        op_index = self.pending_ops.index(op)
        retval = CloudUser.with(consistency: :strong).where({ "_id" => self._id, "pending_ops.#{op_index}._id" => op._id, "pending_ops.#{op_index}.state" => "init" }).update({"$set" => { "pending_ops.#{op_index}.state" => "queued" }})
        unless retval["updatedExisting"]
          self.with(consistency: :strong).reload
          next
        end

        case op.op_type
        when :add_ssh_key
          op.pending_domains.each { |domain| domain.add_ssh_key(self._id, UserSshKey.new.to_obj(op.arguments), op) }
        when :delete_ssh_key
          op.pending_domains.each { |domain| domain.remove_ssh_key(self._id, UserSshKey.new.to_obj(op.arguments), op) }
        end

        # reloading the op reloads the cloud_user and then incorrectly reloads (potentially)
        # the op based on its position within the pending_ops list
        # hence, reloading the cloud_user, and then fetching the op using the op_id stored earlier
        self.with(consistency: :strong).reload
        op = self.pending_ops.find_by(_id: op_id)
        
        op.close_op
        op.delete if op.completed?
      end
      true
    rescue Exception => ex
      Rails.logger.error ex
      Rails.logger.error ex.backtrace
      false
    end
  end
end
