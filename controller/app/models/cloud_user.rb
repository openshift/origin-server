# Primary User model for the broker. It keeps track of plan details, capabilities and ssh-keys for the user.
# @!attribute [r] login
#   @return [String] Login name for the user.
# @!attribute [r] capabilities
#   @return [Hash] Hash representing the capabilities of the user. It is updated using the oo-admin-ctl-user scripts or when a plan changes.
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
# @!attribute [rw] pending_op_groups
#   @return [Array<PendingUserOpGroup>] List of pending operations to be performed on this user
class CloudUser
  include Mongoid::Document
  include Mongoid::Timestamps
  include AccessControllable
  include AccessControlled

  alias_method :mongoid_save, :save

  DEFAULT_SSH_KEY_NAME = "default"

  field :login, type: String
  field :capabilities, as: :_capabilities, type: Hash, default: ->{ default_capabilities }
  field :parent_user_id, type: Moped::BSON::ObjectId
  field :plan_id, type: String
  field :plan_state, type: String
  field :plan_expiration_date, type: Date, default: nil
  field :plan_quantity, type: Integer, default: 1
  field :pending_plan_id, type: String
  field :pending_plan_uptime, type: Time
  field :plan_history, type: Array, default: []
  field :usage_account_id, type: String
  field :consumed_gears, type: Integer, default: 0
  field :email, type: String
  field :currency_cd, type: String, default: nil

  embeds_many :ssh_keys, class_name: UserSshKey.name
  embeds_many :pending_op_groups, class_name: PendingUserOpGroup.name, cascade_callbacks: true
  # embeds_many :identities, class_name: Identity.name, cascade_callbacks: true

  has_many :domains, class_name: Domain.name, dependent: :restrict, foreign_key: :owner_id
  has_many :authorizations, class_name: Authorization.name, dependent: :restrict
  has_many :owned_applications, class_name: Application.name, foreign_key: :owner_id, inverse_of: :owner

  member_as :user

  validates :login, presence: true
  validates :capabilities, presence: true, capabilities: true

  scope :with_plan, any_of({:plan_id.ne => nil}, {:pending_plan_id.ne => nil})
  index({:login => 1}, {:unique => true})
  index({'pending_op_groups.created_at' => 1})

  scope :with_identity_id, lambda{ |id| where(login: normalize_login(id)) }
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
  # authentication with user/pass. :broker_auth is used when the application needs
  # to make a request to the broker on behalf of the user (eg: scale-up)
  #
  # This is a transient attribute and is not persisted
  attr_accessor :auth_method

  # The set of scopes that are currently present on this user.  Scopes limit
  # the available actions on an account to the union of the actions permitted
  # by the supplied scope.  All other actions are forbidden.  Type is Scopes
  #
  # This is a transient attribute and is not persisted
  attr_accessor :scopes

  # Identity support will add the following:
  #
  # # This is a transient attribute and is not persisted
  # attr_accessor :current_identity
  # def current_identity!(provider, uid)
  #  self.current_identity = identities.select{ |i| i.provider == provider && i.uid == uid }.first
  # end

  def ===(other)
    super || (!other.is_a?(Mongoid::Document) ? _id === other : false)
  end

  def inherit_membership
    [as_member]
  end

  def name
    login
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

  def self.normalize_login(login)
    OpenShift::Username.normalize(login.to_s)
  end

  #
  # Identity support will introduce a provider attribute that is used to
  # identify the source of a particular login.  Until then, users are only
  # identified by their login and provider is ignored.
  #
  def self.find_or_create_by_identity(provider, login, create_attributes={}, &block)
    login = normalize_login(login)
    provider = provider.to_s if provider
    user = find_by_identity(nil, login)
    #identity = user.current_identity!(provider, login)
    yield user, login if block_given?
    [user, false]
  rescue Mongoid::Errors::DocumentNotFound
    user = new(create_attributes)
    #user.current_identity = user.identities.build(provider: provider, uid: login)
    #user.login = user.current_identity.id
    user.login = login
    begin
      user.with(safe: true).save
      Lock.create_lock(user.id)
      OpenShift::UserActionLog.action("CREATE_USER", nil, true, "Creating user", 'USER' => user.id, 'LOGIN' => login, 'PROVIDER' => provider)
      [user, true]
    rescue Moped::Errors::OperationFailure
      user = find_by_identity(nil, login)
      raise unless user
      yield user, login if block_given?
      [user, true]
    end
  end

  def self.with_ids_or_logins(ids, logins)
    logins.map! {|login| normalize_login(login)}
    if ids.present?
      if logins.present?
        self.or({:_id.in => ids}, {:login.in => logins})
      else
        self.in(_id: ids)
      end
    else
      self.in(login: logins)
    end
  end

  # Used to add an ssh-key to the user. Use this instead of ssh_keys= so that the key can be propagated to the
  # domains/application that the user has access to.
  def add_ssh_key(key)
    if persisted?
      Lock.run_in_user_lock(self, 1800) do
        op_group = AddSshKeysUserOpGroup.new(keys_attrs: [key.as_document])
        self.pending_op_groups.push op_group
        result_io = ResultIO.new
        self.run_jobs(result_io)
        result_io
      end
    else
      ssh_keys << key
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
    if persisted?
      Lock.run_in_user_lock(self, 1800) do
        key = self.ssh_keys.find_by(name: name)
        op_group = RemoveSshKeysUserOpGroup.new(keys_attrs: [key.as_document])
        self.pending_op_groups.push op_group
        result_io = ResultIO.new
        self.run_jobs(result_io)
        result_io
      end
    else
      ssh_keys.delete_if{ |k| k.name == name }
    end
  end

  def default_capabilities
    {
      "ha" => Rails.application.config.openshift[:default_allow_ha],
      "subaccounts" => false,
      "gear_sizes" => Rails.application.config.openshift[:default_gear_capabilities],
      "max_domains" => Rails.application.config.openshift[:default_max_domains],
      "max_gears" => Rails.application.config.openshift[:default_max_gears],
      "max_teams" => Rails.application.config.openshift[:default_max_teams],
      "view_global_teams" => Rails.application.config.openshift[:default_view_global_teams],
      "max_untracked_addtl_storage_per_gear" =>  Rails.application.config.openshift[:default_max_untracked_addtl_storage_per_gear],
      "max_tracked_addtl_storage_per_gear" =>  Rails.application.config.openshift[:default_max_tracked_addtl_storage_per_gear],
      "private_ssl_certificates" => Rails.application.config.openshift[:default_private_ssl_certificates],
    }
  end

  def inherited_capabilities
    @inherited_capabilities ||= begin
        if self.parent_user_id
          caps = CloudUser.find_by(_id: self.parent_user_id).capabilities
          caps.slice(*Array(caps['inherit_on_subaccounts'])).freeze
        end
      rescue Mongoid::Errors::DocumentNotFound
      end || {}.freeze
  end

  class CapabilityProxy < SimpleDelegator
    def initialize(base, inherited)
      @inherited = inherited
      super base
    end
    def [](key)
      @inherited[key] || super
    end
    def deep_dup
      __getobj__.deep_dup.merge!(@inherited.deep_dup)
    end
    def to_hash
      deep_dup
    end
    def serializable_hash
      to_hash
    end
  end

  #
  # The capabilities object should always return inherited properties if they are
  # set (and inheritable from the parent account), otherwise it should return
  # the stored capabilities.  If the parent user is changed, the underlying
  # capability should be returned.
  #
  # Note: Mongoid handles dirty tracking on hashes whenever the accessor is called,
  #       therefore each call to capabilities must invoke the underlying object.
  #
  alias_method :_capabilities, :capabilities
  def capabilities
    self._capabilities = {} unless self._capabilities
    caps = self._capabilities
    CapabilityProxy.new(caps, inherited_capabilities)
  end

  def set_capabilities(caps, clear_existing_caps=false)
    Lock.run_in_user_lock(self) do
      self._capabilities = {} unless self._capabilities
      if clear_existing_caps
        self._capabilities.clear
        user_caps = capabilities
        user_caps.each do |k, v|
          if v.is_a?(Array)
            self._capabilities[k] = []
          elsif v.is_a?(Hash)
            self._capabilities[k] = {}
          elsif v.is_a?(Boolean)
            self._capabilities[k] = false
          elsif v.is_a?(Integer) or v.is_a?(Float)
            self._capabilities[k] = 0
          else
            raise OpenShift::UserException.new("Capability type not found for '#{k} : #{v}'")
          end
        end
      end
      self._capabilities.merge!(caps.deep_dup)
    end
  end

  def ha
    capabilities["ha"] || false
  end

  def ha=(m)
    self._capabilities["ha"] = m if capabilities["ha"] != m
  end

  def max_gears
    capabilities["max_gears"]
  end

  def max_gears=(m)
    self._capabilities["max_gears"] = m if capabilities["max_gears"] != m
  end

  def max_domains
    capabilities["max_domains"] || Rails.application.config.openshift[:default_max_domains]
  end

  def max_domains=(m)
    self._capabilities["max_domains"] = m if capabilities["max_domains"] != m
  end

  def max_teams
    capabilities["max_teams"] || Rails.application.config.openshift[:default_max_teams]
  end

  def max_teams=(m)
    self._capabilities["max_teams"] = m if capabilities["max_teams"] != m
  end

  def view_global_teams
    capabilities["view_global_teams"] || Rails.application.config.openshift[:default_view_global_teams]
  end

  def view_global_teams=(m)
    self._capabilities["view_global_teams"] = m if capabilities["view_global_teams"] != m
  end

  def plan_upgrade_enabled
    capabilities["plan_upgrade_enabled"] || false
  end

  def plan_upgrade_enabled=(m)
    self._capabilities["plan_upgrade_enabled"] = m if capabilities["plan_upgrade_enabled"] != m
  end

  def subaccounts
    capabilities["subaccounts"] || false
  end

  def subaccounts=(m)
    self._capabilities["subaccounts"] = m if capabilities["subaccounts"] != m
  end

  def inherit_on_subaccounts
    capabilities["inherit_on_subaccounts"] || []
  end

  def add_capability_inherit_on_subaccounts(capability)
    inherit_caps = capabilities["inherit_on_subaccounts"] || []
    unless inherit_caps.include?(capability)
      self._capabilities["inherit_on_subaccounts"] = inherit_caps + [capability]
    end
  end

  def remove_capability_inherit_on_subaccounts(capability)
    inherit_caps = capabilities["inherit_on_subaccounts"] || []
    if inherit_caps.include?(capability)
      self._capabilities["inherit_on_subaccounts"] = inherit_caps - [capability]
    end
  end

  def allowed_gear_sizes
    capabilities["gear_sizes"]
  end

  def add_gear_size(gear_size)
    available_sizes = Rails.configuration.openshift[:gear_sizes]
    unless available_sizes.include?(gear_size)
      raise Exception.new("\nERROR: Size '#{gear_size}' is not defined. Available gear sizes: #{available_sizes.join ', '}.")
    end
    unless capabilities['gear_sizes'].include?(gear_size)
      self._capabilities['gear_sizes'] = capabilities['gear_sizes'] + [gear_size]
      self.save!
    end
    domains.each do |d|
      if (allowed_gear_sizes - d.allowed_gear_sizes) == [gear_size]
        d.allowed_gear_sizes = allowed_gear_sizes
        d.save!
      end
    end
  end

  def remove_gear_size(gear_size)
    caps = capabilities
    unless caps["gear_sizes"].include?(gear_size)
      puts "User #{self.login} does not have gear size #{gear_size} in its capabilities."
      return
    end
    self._capabilities["gear_sizes"] = caps["gear_sizes"] - [gear_size]
    self.save!
    domains.each do |d|
      d.allowed_gear_sizes = (allowed_gear_sizes & d.allowed_gear_sizes)
      d.save!
    end
  end

  def max_storage
    (max_tracked_additional_storage + max_untracked_additional_storage)
  end

  def max_untracked_additional_storage
    capabilities['max_untracked_addtl_storage_per_gear'] || Rails.application.config.openshift[:default_max_untracked_addtl_storage_per_gear]
  end

  def max_untracked_additional_storage=(m)
    self._capabilities["max_untracked_addtl_storage_per_gear"] = m if capabilities["max_untracked_addtl_storage_per_gear"] != m
  end

  def max_tracked_additional_storage
    capabilities['max_tracked_addtl_storage_per_gear'] || Rails.application.config.openshift[:default_max_tracked_addtl_storage_per_gear]
  end

  def max_tracked_additional_storage=(m)
    self._capabilities["max_tracked_addtl_storage_per_gear"] = m if capabilities["max_tracked_addtl_storage_per_gear"] != m
  end

  def usage_rates
    {}
  end

  def private_ssl_certificates
    capabilities["private_ssl_certificates"] || false
  end

  def private_ssl_certificates=(m)
    self._capabilities["private_ssl_certificates"] = m if capabilities["private_ssl_certificates"] != m
  end

  # Delete user and all its artifacts like domains, applications associated with the user
  def force_delete
    while domain = Domain.where(owner: self).first
      while app = Application.where(domain: domain).first
        app.destroy_app
      end
      domain.delete
    end
    while team = Team.where(owner: self).first
      team.destroy_team
    end

    # will need to reload from primary to ensure that mongoid doesn't validate based on its cache
    # and prevent us from deleting this user because of the :dependent :restrict clause
    self.reload.delete
  end

  #updates user's plan_id
  def update_plan(plan_id, plan_quantity=1)
    Lock.run_in_user_lock(self) do
      self.plan_id = plan_id
      self.plan_quantity = plan_quantity
      self.save!
    end
  end

  # Runs all pending jobs and stops at the first failure.
  #
  # IMPORTANT: Callers should take the user lock prior to calling run_jobs
  #
  # IMPORTANT: When changing jobs, be sure to leave old jobs runnable so that pending_ops
  #   that are inserted during a running upgrade can continue to complete.
  #
  # == Returns:
  # True on success or false on failure
  def run_jobs(result_io=nil, continue_on_successful_rollback=false)
    result_io = ResultIO.new if result_io.nil?
    op_group = nil
    while self.pending_op_groups.count > 0
      rollback_pending = false
      op_group = self.pending_op_groups.first

      begin
        op_group.elaborate(self) if op_group.pending_ops.count == 0

        if op_group.pending_ops.where(:state => :rolledback).count > 0
          rollback_pending = true
          raise Exception.new("Op group is already being rolled back.")
        end

        op_group.execute(result_io)
        op_group.delete
      rescue Exception => e_orig
        Rails.logger.error "Encountered error during execute '#{e_orig.message}'"
        # don't log the error stacktrace if this exception was raised just to trigger a rollback
        Rails.logger.debug e_orig.backtrace.inspect unless rollback_pending

        #rollback
        begin
          # reload the user before a rollback
          self.reload
          op_group.execute_rollback(result_io)
          op_group.delete
        rescue Exception => e_rollback
          Rails.logger.error "Error during rollback"
          Rails.logger.error e_rollback.message
          Rails.logger.error e_rollback.backtrace.join("\n")

          # if the original exception was raised just to trigger a rollback
          # then the rollback exception is the only thing of value and hence return/raise it
          raise e_rollback if rollback_pending
        end

        # raise the original exception if it was the actual exception that led to the rollback
        # if not, then we should just continue execution of any remaining op_groups.
        # The continue_on_successful_rollback flag is used by the oo-admin-clear-pending-ops script
        unless rollback_pending or continue_on_successful_rollback
          if e_orig.respond_to? 'resultIO' and e_orig.resultIO
            e_orig.resultIO.append result_io unless e_orig.resultIO == result_io
          end
          raise e_orig
        end
      end

      self.reload
    end
    true
  end

end
