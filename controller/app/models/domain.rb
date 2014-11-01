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
  extend PreAndPostCondition

  field :namespace, type: String
  field :canonical_namespace, type: String
  field :env_vars, type: Array, default: []
  field :allowed_gear_sizes, type: Array
  embeds_many :system_ssh_keys, class_name: SystemSshKey.name
  belongs_to :owner, class_name: CloudUser.name
  has_many :applications, class_name: Application.name, dependent: :restrict
  embeds_many :pending_ops, class_name: PendingDomainOps.name, cascade_callbacks: true

  has_members default_role: :admin

  index({:canonical_namespace => 1}, {:unique => true})
  index({:owner_id => 1})
  create_indexes

  # non-persisted fields used to store info about the applications in this domain
  attr_accessor :application_count
  attr_accessor :gear_counts
  attr_accessor :available_gears
  attr_accessor :max_storage_per_gear
  attr_accessor :usage_rates
  attr_accessor :private_ssl_certificates

  validates :namespace,
    #presence: {message: "Namespace is required and cannot be blank."},
    format:   {with: DOMAIN_NAME_REGEX, message: "Invalid namespace. Namespace must only contain alphanumeric characters.", allow_nil: true},
    length:   {maximum: NAMESPACE_MAX_LENGTH, minimum: NAMESPACE_MIN_LENGTH, message: "Must be a minimum of #{NAMESPACE_MIN_LENGTH} and maximum of #{NAMESPACE_MAX_LENGTH} characters."}

  validate do |d|
    if d.allowed_gear_sizes_changed?
      new_gear_sizes = Array(d.allowed_gear_sizes).map{ |g| g.to_s.presence }.compact
      valid_gear_sizes = OpenShift::ApplicationContainerProxy.valid_gear_sizes
      allowed_gear_sizes = valid_gear_sizes & (d.has_owner? and d.owner.allowed_gear_sizes or [])
      invalid_gear_sizes = new_gear_sizes - valid_gear_sizes
      disallowed_gear_sizes = new_gear_sizes - allowed_gear_sizes
      if invalid_gear_sizes.present?
        d.errors.add :allowed_gear_sizes, "The following gear sizes are invalid: #{invalid_gear_sizes.to_sentence}"
      elsif disallowed_gear_sizes.present?
        d.errors.add :allowed_gear_sizes, "The following gear sizes are not available to this account: #{disallowed_gear_sizes.to_sentence}"
      else
        d.allowed_gear_sizes = new_gear_sizes.uniq
      end
    end
  end

  def self.validation_map
    {namespace: 106, allowed_gear_sizes: 110, members: 222}
  end

  # Invoke save with a rescue for a duplicate exception
  #
  # == Returns:
  #   True if the domain was saved.
  def save(options={})
    super(options)
  rescue Moped::Errors::OperationFailure => e
    raise OpenShift::UserException.new("Namespace '#{namespace}' is already in use. Please choose another.", 103, "id") if [11000, 11001].include?(e.details['code'])
    raise
  end

  def self.create!(opts)
    owner = opts[:owner]
    domain = nil
    Lock.run_in_user_lock(owner) do
      allowed_domains = opts[:_allowed_domains] || owner.max_domains
      opts.delete(:allowed_gear_sizes) if opts[:allowed_gear_sizes].nil?
      domain = Domain.new(opts)
      unless pre_and_post_condition(
               lambda{ Domain.where(owner: owner).count < allowed_domains },
               lambda{ Domain.where(owner: owner).count <= allowed_domains },
               lambda{ domain.save! },
               lambda{ domain.destroy rescue nil }
             )
        raise OpenShift::UserException.new("You may not have more than #{pluralize(allowed_domains, "domain")}.", 103, nil, nil, :conflict)
      end
    end
    domain
  end

  def self.sort_by_original(user)
    lambda{ |d| [user._id == d.owner_id ? 0 : 1, d.created_at] }
  end

  def self.with_gear_counts(domains=queryable)
    domains = domains.to_a
    info_by_domain = Application.with_gear_counts(domains).group_by{ |a| a['domain_id'] }
    domains.each do |d|
      if info = info_by_domain[d._id]
        d.application_count = info.length
        d.gear_counts = info.inject({}) do |h, v|
          v['gear_sizes'].each_pair do |size, count|
            h[size] ||= 0
            h[size] += count
          end
          h
        end
      else
        d.application_count = 0
        d.gear_counts = {}
      end
    end
  end

  def with_gear_counts
    self.class.with_gear_counts([self]).first
  end

  def self.with_owner_info(domains=queryable)
    domains = domains.to_a
    owners_by_id = CloudUser.in(_id: domains.map(&:owner_id)).group_by(&:_id)
    domains.each do |d|
      if owners_by_id[d.owner_id].present?
        owner = owners_by_id[d.owner_id].first
        d.available_gears = owner.max_gears - owner.consumed_gears
        d.max_storage_per_gear = owner.max_storage
        d.usage_rates = owner.usage_rates
        d.private_ssl_certificates = owner.private_ssl_certificates
      end
    end
  end

  def with_owner_info
    self.class.with_owner_info([self]).first
  end

  before_save prepend: true do
    self.namespace = self.namespace.downcase
  end

  before_save prepend: true do
    self.canonical_namespace = namespace.present? ? namespace.downcase : nil
    if has_owner? && (allowed_gear_sizes.nil? || (persisted? && owner_id_changed?))
      self.allowed_gear_sizes = owner.allowed_gear_sizes
    end
  end

  # Defend against namespace changes after creation.
  before_update do
    if canonical_namespace_changed? && Application.where(domain_id: _id).present?
      raise OpenShift::UserException.new("Domain contains applications. Delete applications first before changing the domain namespace.", 128)
    end
  end

  # Setter for domain namespace - sets the namespace and the canonical_namespace
  def namespace=(domain_name)
    self.canonical_namespace = domain_name.downcase
    super
  end

  # Capability-type objects inherited from the domain owner
  # Look up in owner object when faults
  def max_storage_per_gear
    @max_storage_per_gear ||= owner.max_storage
  end
  def available_gears
    @available_gears ||= owner.max_gears - owner.consumed_gears
  end
  def usage_rates
    @usage_rates ||= owner.usage_rates
  end
  def private_ssl_certificates
    @private_ssl_certificates = owner.private_ssl_certificates if @private_ssl_certificates.nil?
    @private_ssl_certificates
  end

  def inherit_membership
    members.select(&:user?).map(&:clone)
  end

  def add_system_ssh_keys(ssh_keys)
    ssh_keys_to_rm = []
    ssh_keys.each do |new_key|
      self.system_ssh_keys.each do |cur_key|
        if cur_key.name == new_key.name
          ssh_keys_to_rm << cur_key.as_document
        end
      end
    end

    # if an ssh key being added has the same name as an existing key, then remove the previous keys first
    Domain.where(_id: self.id).update_all({ "$pullAll" => { system_ssh_keys: ssh_keys_to_rm }}) unless ssh_keys_to_rm.empty?

    keys_attrs = ssh_keys.map { |k| k.as_document }
    pending_op = AddSystemSshKeysDomainOp.new(keys_attrs: keys_attrs)
    pending_op.set_created_at
    Domain.where(_id: self.id).update_all({ "$push" => { pending_ops: pending_op.as_document }, "$pushAll" => { system_ssh_keys: keys_attrs }})
  end

  def remove_system_ssh_keys(remove_key)
    if remove_key.is_a? Array
      ssh_keys = remove_key
    else
      ssh_keys = self.system_ssh_keys.find_by(component_id: remove_key) rescue []
      ssh_keys = [ssh_keys].flatten
    end
    return if ssh_keys.empty?
    keys_attrs = ssh_keys.map { |k| k.as_document }
    pending_op = RemoveSystemSshKeysDomainOp.new(keys_attrs: keys_attrs)
    pending_op.set_created_at
    Domain.where(_id: self.id).update_all({ "$push" => { pending_ops: pending_op.as_document }, "$pullAll" => { system_ssh_keys: keys_attrs }})
  end

  def update_capabilities(old_caps, new_caps, parent_op=nil)
    pending_op = UpdateCapabilitiesDomainOp.new(old_capabilities: old_caps, new_capabilities: new_caps, parent_op: parent_op)
    self.pending_ops.push pending_op
    self.run_jobs
  end

  def add_env_variables(variables)
    env_vars_to_rm = []
    variables.each do |new_var|
      self.env_vars.each do |cur_var|
        if cur_var["key"] == new_var["key"]
          if !(new_var["unique"] || cur_var["unique"])
            env_vars_to_rm << cur_var.dup
          else
            raise OpenShift::UserException.new(
              "This application attempted to create a unique domain environment variable #{new_var["key"]} which already exists in this domain (#{namespace}).",
              134, nil, nil, :forbidden)
          end
        end
      end
    end

    # if this is an update to an existing environment variable, remove the previous ones first
    Domain.where(_id: self.id).update_all({ "$pullAll" => { env_vars: env_vars_to_rm }}) unless env_vars_to_rm.empty?

    pending_op = AddEnvVarsDomainOp.new(variables: variables)
    pending_op.set_created_at
    Domain.where(_id: self.id).update_all({ "$push" => { pending_ops: pending_op.as_document }, "$pushAll" => { env_vars: variables }})
  end

  def remove_env_variables(remove_key)
    if remove_key.is_a? Array
      variables = remove_key
    else
      variables = self.env_vars.select { |env| env["component_id"]==remove_key }
    end
    return if variables.empty?
    pending_op = RemoveEnvVarsDomainOp.new(variables: variables)
    pending_op.set_created_at
    Domain.where(_id: self.id).update_all({ "$push" => { pending_ops: pending_op.as_document }, "$pullAll" => { env_vars: variables }})
  end

  def members_changed(added, removed, changed_roles, parent_op)
    pending_op = ChangeMembersDomainOp.new(members_added: added.presence, members_removed: removed.presence, roles_changed: changed_roles.presence)
    self.pending_ops.push pending_op
  end

  def validate_gear_sizes!(gear_sizes, field="gear_size")
    valid_sizes = OpenShift::ApplicationContainerProxy.valid_gear_sizes & allowed_gear_sizes & owner.allowed_gear_sizes

    if valid_sizes.empty?
      raise OpenShift::UserException.new(
        "The owner of the domain #{namespace} has disabled all gear sizes from being created.  You will not be able to add any cartridges in this domain.",
        134, nil, nil, :forbidden)
    end

    invalid_sizes = (gear_sizes - valid_sizes).map {|s| "'#{s}'"}
    raise OpenShift::UserException.new("The gear sizes #{invalid_sizes.to_sentence} are not valid for this domain. Allowed sizes: #{valid_sizes.to_sentence}.", 134, field) if (invalid_sizes.length > 1)
    raise OpenShift::UserException.new("The gear size #{invalid_sizes.to_sentence} is not valid for this domain. Allowed sizes: #{valid_sizes.to_sentence}.", 134, field) if (invalid_sizes.length == 1)
    true
  end

  # Runs all jobs in "init" phase and stops at the first failure.
  #
  # IMPORTANT: When changing jobs, be sure to leave old jobs runnable so that pending_ops
  #   that are inserted during a running upgrade can continue to complete.
  #
  # == Returns:
  # True on success or false on failure
  def run_jobs
    wait_ctr = 0
    begin
      while self.pending_ops.count > 0
        op = self.pending_ops.first
        
        # a stuck op could move to the completed state if its pending applications are deleted
        if op.completed?
          op.delete
          self.reload
          next
        end

        # store the op._id to load it later after a reload
        # this is required to prevent a reload from replacing it with another one based on position
        op_id = op._id

        # try to do an update on the pending_op state and continue ONLY if successful
        op_index = self.pending_ops.index(op)
        t_now = Time.now.to_i

        id_condition = {"_id" => self._id, "pending_ops.#{op_index}._id" => op_id}
        runnable_condition = {"$or" => [
          # The op is not yet running
          {"pending_ops.#{op_index}.state" => "init" },
          # The op is in the running state and has timed out
          { "pending_ops.#{op_index}.state" => "queued", "pending_ops.#{op_index}.queued_at" => {"$lt" => (t_now - run_jobs_queued_timeout)} }
        ]}
 
        queued_values = {"pending_ops.#{op_index}.state" => "queued", "pending_ops.#{op_index}.queued_at" => t_now}
        reset_values  = {"pending_ops.#{op_index}.state" => "init",   "pending_ops.#{op_index}.queued_at" => 0}
 
        retval = Domain.where(id_condition.merge(runnable_condition)).update({"$set" => queued_values})
        if retval["updatedExisting"]
          wait_ctr = 0
        elsif wait_ctr < run_jobs_max_retries
          self.reload
          sleep run_jobs_retry_sleep
          wait_ctr += 1
          next
        else
          raise OpenShift::LockUnavailableException.new("Unable to perform action on domain object. Another operation is already running.", 171)
        end

        begin
          op.execute

          # reloading the op reloads the domain and then incorrectly reloads (potentially)
          # the op based on its position within the pending_ops list
          # hence, reloading the domain, and then fetching the op using the op_id stored earlier
          self.reload
          op = self.pending_ops.find_by(_id: op_id)
  
          op.close_op
          op.delete if op.completed?
        rescue Exception => op_ex
          # doing this in rescue instead of ensure so that the state change happens only in case of exceptions
          Domain.where(id_condition.merge(queued_values)).update({"$set" => reset_values})
          raise op_ex
        end
      end
      true
    rescue Exception => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace
      raise e
    end
  end

  private
    def run_jobs_max_retries;    10;    end
    def run_jobs_retry_sleep;    5;     end
    def run_jobs_queued_timeout; 30*60; end

    extend ActionView::Helpers::TextHelper # for pluralize()
end
