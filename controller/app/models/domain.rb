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
  field :allowed_gear_sizes, type: Array, default: []
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

  validates :namespace,
    #presence: {message: "Namespace is required and cannot be blank."},
    format:   {with: DOMAIN_NAME_REGEX, message: "Invalid namespace. Namespace must only contain alphanumeric characters.", allow_blank: true},
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

  def self.with_gear_counts(domains=queryable.to_a)
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
    end
  end

  def with_gear_counts
    self.class.with_gear_counts([self]).first
  end

  before_save prepend: true do
    self.canonical_namespace = namespace.present? ? namespace.downcase : nil
    if has_owner?
      self.allowed_gear_sizes = owner.allowed_gear_sizes if owner_id_changed? || !persisted?
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
    members.clone
  end

  def self.legacy_accessible(to)
    to.respond_to?(:domains) ? to.domains : where(owner: to)
  end

  def add_system_ssh_keys(ssh_keys)
    keys_attrs = ssh_keys.map{|k| k.attributes.dup}
    pending_op = PendingDomainOps.new(op_type: :add_domain_ssh_keys, arguments: { "keys_attrs" => keys_attrs }, on_apps: applications, created_at: Time.now, state: "init")
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
    keys_attrs = ssh_keys.map{|k| k.attributes.dup}
    pending_op = PendingDomainOps.new(op_type: :delete_domain_ssh_keys, arguments: {"keys_attrs" => keys_attrs}, on_apps: applications, created_at: Time.now, state: "init")
    Domain.where(_id: self.id).update_all({ "$push" => { pending_ops: pending_op.serializable_hash_with_timestamp }, "$pullAll" => { system_ssh_keys: keys_attrs }})
  end

  def add_env_variables(variables)
    env_vars_to_rm = []
    variables.each do |new_var|
      self.env_vars.each do |cur_var|
        if cur_var["key"] == new_var["key"] && cur_var["value"] != new_var["value"]
          env_vars_to_rm << cur_var.dup
        end
      end
    end

    pending_op = PendingDomainOps.new(op_type: :add_env_variables, arguments: {"variables" => variables}, on_apps: applications, created_at: Time.now, state: "init")
    Domain.where(_id: self.id).update_all({ "$push" => { pending_ops: pending_op.serializable_hash_with_timestamp }, "$pushAll" => { env_vars: variables }})

    # if this is an update to an existing environment variable, remove the previous ones
    Domain.where(_id: self.id).update_all({ "$pullAll" => { env_vars: env_vars_to_rm }}) unless env_vars_to_rm.empty?
  end

  def remove_env_variables(remove_key)
    if remove_key.is_a? Array
      variables = remove_key
    else
      variables = self.env_vars.select { |env| env["component_id"]==remove_key }
    end
    return if variables.empty?
    pending_op = PendingDomainOps.new(op_type: :remove_env_variables, arguments: {"variables" => variables}, on_apps: applications, created_at: Time.now, state: "init")
    Domain.where(_id: self.id).update_all({ "$push" => { pending_ops: pending_op.serializable_hash_with_timestamp }, "$pullAll" => { env_vars: variables }})
  end

  # Runs all jobs in "init" phase and stops at the first failure.
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

        case op.op_type
        when :change_members
          self.applications.each do |app|
            app.with_lock do |a|
              a.change_member_roles(Array(op.args['changed']), [:domain])
              a.remove_members(Array(op.args['removed']), [:domain])
              a.add_members(Array(op.args['added']).map{ |m| self.class.to_member(m) }, [:domain])
              a.save!
              a.run_jobs # FIXME this needs to recover and continue
            end
          end      
          op.set(:state, :completed)
          
        when :add_domain_ssh_keys
          ssh_keys = op.arguments["keys_attrs"].map{|k| SystemSshKey.new.to_obj(k)}
          op.pending_apps.each { |app| app.add_ssh_keys(nil, ssh_keys, op) }
        when :delete_domain_ssh_keys
          ssh_keys = op.arguments["keys_attrs"].map{|k| SystemSshKey.new.to_obj(k)}
          op.pending_apps.each { |app| app.remove_ssh_keys(nil, ssh_keys, op) }
        when :add_env_variables
          op.pending_apps.each { |app| app.add_env_variables(op.arguments["variables"], op) }
        when :remove_env_variables
          op.pending_apps.each { |app| app.remove_env_variables(op.arguments["variables"], op) }
        end

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
