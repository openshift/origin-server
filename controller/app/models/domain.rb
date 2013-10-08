# Represents a OpenShift Domain. A {CloudUser} can own multiple domains.
# @!attribute [r] namespace
#   @return [String] Namespace reserved for this domain.
#     @see {Domain#update_namespace}
# @!attribute [r] env_vars
#   @return [Array[Hash]] List of domain wide environment variables to be created on all {Application}s under the domain.
#     @see {Domain#add_env_variables}, {Domain#remove_env_variables}
# @!attribute [r] system_ssh_keys
#   @return [Array[SystemSshKey]] List of SSH keys to be made available on all {Application}s under the domain.
#     These keys are used when applications need to push code to each other. Eg: Jenkins
#     @see {Domain#add_domain_ssh_keys}, {Domain#remove_domain_ssh_key}
# @!attribute [r] owner
#   @return [CloudUser] The {CloudUser} that owns this domain.
# @!attribute [r] applications
#   @return [Array[Application]] List of {Application}s under the domain.
# @!attribute [r] pending_ops
#   @return [Array[PendingDomainOps]] List of {PendingDomainOps} that need to be performed on this domain.
class Domain
  NAMESPACE_MAX_LENGTH = 16 unless defined? NAMESPACE_MAX_LENGTH
  NAMESPACE_MIN_LENGTH = 1 unless defined? NAMESPACE_MIN_LENGTH

  # This is the current regex for validations for new domains
  DOMAIN_NAME_REGEX = /\A[A-Za-z0-9]+\z/
  def self.check_name!(name)
    if name.blank? or name !~ DOMAIN_NAME_REGEX
      raise Mongoid::Errors::DocumentNotFound.new(Domain, nil, [name])
    end
    name
  end

  include Mongoid::Document
  include Mongoid::Timestamps
  include Membership

  field :namespace, type: String
  field :canonical_namespace, type: String
  field :env_vars, type: Array, default: []
  field :allowed_gear_sizes, type: Array
  embeds_many :system_ssh_keys, class_name: SystemSshKey.name
  belongs_to :owner, class_name: CloudUser.name
  has_many :applications, class_name: Application.name, dependent: :restrict
  embeds_many :pending_ops, class_name: PendingDomainOps.name

  has_members default_role: :admin

  index({:canonical_namespace => 1}, {:unique => true})
  index({:owner_id => 1})
  create_indexes

  # non-persisted fields used to store info about the applications in this domain
  attr_accessor :application_count
  attr_accessor :gear_counts
  attr_accessor :available_gears
  attr_accessor :max_storage_per_gear  

  validates :namespace,
    #presence: {message: "Namespace is required and cannot be blank."},
    format:   {with: DOMAIN_NAME_REGEX, message: "Invalid namespace. Namespace must only contain alphanumeric characters.", allow_nil: true},
    length:   {maximum: NAMESPACE_MAX_LENGTH, minimum: NAMESPACE_MIN_LENGTH, message: "Must be a minimum of #{NAMESPACE_MIN_LENGTH} and maximum of #{NAMESPACE_MAX_LENGTH} characters."},
    blacklisted: {message: "Namespace is not allowed.  Please choose another."}

  validate do |d|
    if d.allowed_gear_sizes_changed?
      new_gear_sizes = Array(d.allowed_gear_sizes).map{ |g| g.to_s.presence }.compact
      valid_gear_sizes = OpenShift::ApplicationContainerProxy.valid_gear_sizes & (d.has_owner? and d.owner.allowed_gear_sizes or [])
      invalid_gear_sizes = new_gear_sizes - valid_gear_sizes
      if invalid_gear_sizes.present?
        d.errors.add :allowed_gear_sizes, "The following gear sizes are invalid: #{invalid_gear_sizes.to_sentence}"
      else
        d.allowed_gear_sizes = new_gear_sizes.uniq
      end
    end
  end

  def self.validation_map
    {namespace: 106, allowed_gear_sizes: 110}
  end

  def self.sort_by_original(user)
    lambda{ |d| [user._id == d.owner_id ? 0 : 1, d.created_at] }
  end

  def self.with_gear_counts(domains=queryable)
    domains = domains.to_a
    owners_by_id = CloudUser.in(_id: domains.map(&:owner_id)).group_by(&:_id)
    info_by_domain = Application.in(domain_id: domains.map(&:_id)).with_gear_counts.group_by{ |a| a['domain_id'] }
    domains.each do |d|
      if info = info_by_domain[d._id]
        d.application_count = info.length
        d.gear_counts = info.inject({}) do |h, v|
          v['gears'].each_pair do |size,count|
            h[size] ||= 0
            h[size] += count
          end
          h
        end
      else
        d.application_count = 0
        d.gear_counts = {}
      end

      if owners_by_id[d.owner_id].present?
        owner = owners_by_id[d.owner_id].first
        d.available_gears = owner.max_gears - owner.consumed_gears
        d.max_storage_per_gear = owner.max_storage
      end
    end
  end

  def with_gear_counts
    self.class.with_gear_counts([self]).first
  end

  before_save prepend: true do
    self.canonical_namespace = namespace.present? ? namespace.downcase : nil
    if has_owner? && (allowed_gear_sizes.nil? || (persisted? && owner_id_changed?))
      self.allowed_gear_sizes = owner.allowed_gear_sizes
    end
  end

  # Defend against namespace changes after creation.
  before_update do
    if namespace_changed? && Application.where(domain_id: _id).present?
      raise OpenShift::UserException.new("Domain contains applications. Delete applications first before changing the domain namespace.", 128)
    end
  end

  # Setter for domain namespace - sets the namespace and the canonical_namespace
  def namespace=(domain_name)
    self.canonical_namespace = domain_name.downcase
    super
  end


  # Invoke save! with a rescue for a duplicate exception
  #
  # == Returns:
  #   True if the domain was saved.
  def save_with_duplicate_check!
    self.save!
  rescue Moped::Errors::OperationFailure => e
    raise OpenShift::UserException.new("Namespace '#{namespace}' is already in use. Please choose another.", 103, "id") if [11000, 11001].include?(e.details['code'])
    raise
  end

  def inherit_membership
    members.map{ |m| m.clone }
  end

  def add_system_ssh_keys(ssh_keys)
    ssh_keys_to_rm = []
    ssh_keys.each do |new_key|
      self.system_ssh_keys.each do |cur_key|
        if cur_key.name == new_key.name
          ssh_keys_to_rm << cur_key.to_key_hash()
        end
      end
    end

    # if an ssh key being added has the same name as an existing key, then remove the previous keys first
    Domain.where(_id: self.id).update_all({ "$pullAll" => { system_ssh_keys: ssh_keys_to_rm }}) unless ssh_keys_to_rm.empty?

    #keys_attrs = ssh_keys.map{|k| k.attributes.dup}
    #pending_op = PendingDomainOps.new(op_type: :add_domain_ssh_keys, arguments: { "keys_attrs" => keys_attrs }, on_apps: applications, created_at: Time.now, state: "init")
    keys_attrs = ssh_keys.map { |k| k.to_key_hash() }
    pending_op = AddSystemSshKeysDomainOp.new(keys_attrs: keys_attrs, on_apps: applications)
    Domain.where(_id: self.id).update_all({ "$push" => { pending_ops: pending_op.serializable_hash_with_timestamp }, "$pushAll" => { system_ssh_keys: keys_attrs }})
  end

  def remove_system_ssh_keys(remove_key)
    if remove_key.is_a? Array
      ssh_keys = remove_key
    else
      ssh_keys = self.system_ssh_keys.find_by(component_id: remove_key) rescue []
      ssh_keys = [ssh_keys].flatten
    end
    return if ssh_keys.empty?
    #keys_attrs = ssh_keys.map{|k| k.attributes.dup}
    #pending_op = PendingDomainOps.new(op_type: :delete_domain_ssh_keys, arguments: {"keys_attrs" => keys_attrs}, on_apps: applications, created_at: Time.now, state: "init")
    keys_attrs = ssh_keys.map { |k| k.to_key_hash() }
    pending_op = RemoveSystemSshKeysDomainOp.new(keys_attrs: keys_attrs, on_apps: applications)
    Domain.where(_id: self.id).update_all({ "$push" => { pending_ops: pending_op.serializable_hash_with_timestamp }, "$pullAll" => { system_ssh_keys: keys_attrs }})
  end

  def add_env_variables(variables)
    env_vars_to_rm = []
    variables.each do |new_var|
      self.env_vars.each do |cur_var|
        if cur_var["key"] == new_var["key"]
          env_vars_to_rm << cur_var.dup
        end
      end
    end

    # if this is an update to an existing environment variable, remove the previous ones first
    Domain.where(_id: self.id).update_all({ "$pullAll" => { env_vars: env_vars_to_rm }}) unless env_vars_to_rm.empty?

    #pending_op = PendingDomainOps.new(op_type: :add_env_variables, arguments: {"variables" => variables}, on_apps: applications, created_at: Time.now, state: "init")
    pending_op = AddEnvVarsDomainOp.new(variables: variables, on_apps: applications)
    Domain.where(_id: self.id).update_all({ "$push" => { pending_ops: pending_op.serializable_hash_with_timestamp }, "$pushAll" => { env_vars: variables }})
  end

  def remove_env_variables(remove_key)
    if remove_key.is_a? Array
      variables = remove_key
    else
      variables = self.env_vars.select { |env| env["component_id"]==remove_key }
    end
    return if variables.empty?
    #pending_op = PendingDomainOps.new(op_type: :remove_env_variables, arguments: {"variables" => variables}, on_apps: applications, created_at: Time.now, state: "init")
    pending_op = RemoveEnvVarsDomainOp.new(variables: variables, on_apps: applications)
    Domain.where(_id: self.id).update_all({ "$push" => { pending_ops: pending_op.serializable_hash_with_timestamp }, "$pullAll" => { env_vars: variables }})
  end

  def members_changed(added, removed, changed_roles)
    pending_op = ChangeMembersDomainOp.new(members_added: added.presence, members_removed: removed.presence, roles_changed: changed_roles.presence)
    self.pending_ops.push pending_op
  end

  # Runs all jobs in "init" phase and stops at the first failure.
  #
  # IMPORTANT: When changing jobs, be sure to leave old jobs runnable so that pending_ops
  #   that are inserted during a running upgrade can continue to complete.
  #
  # == Returns:
  # True on success or false on failure
  def run_jobs
    begin
      while self.pending_ops.where(state: "init").count > 0
        op = self.pending_ops.where(state: "init").first

        # store the op._id to load it later after a reload
        # this is required to prevent a reload from replacing it with another one based on position
        op_id = op._id

        # try to do an update on the pending_op state and continue ONLY if successful
        op_index = self.pending_ops.index(op)
        retval = Domain.where({ "_id" => self._id, "pending_ops.#{op_index}._id" => op._id, "pending_ops.#{op_index}.state" => "init" }).update({"$set" => { "pending_ops.#{op_index}.state" => "queued" }})

        unless retval["updatedExisting"]
          self.reload
          next
        end

        op.execute

        # reloading the op reloads the domain and then incorrectly reloads (potentially)
        # the op based on its position within the pending_ops list
        # hence, reloading the domain, and then fetching the op using the op_id stored earlier
        self.reload
        op = self.pending_ops.find_by(_id: op_id)

        op.close_op
        op.delete if op.completed?
      end
      true
    rescue Exception => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace
      raise e
    end
  end
end
