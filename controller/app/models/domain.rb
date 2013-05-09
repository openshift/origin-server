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
# @!attribute [r] user_ids
#   @return [Array[Moped::BSON::ObjectId]] List of IDs of {CloudUser}s that have access to {Application}s within this domain.
# @!attribute [r] applications
#   @return [Array[Application]] List of {Application}s under the domain.
# @!attribute [r] pending_ops
#   @return [Array[PendingDomainOps]] List of {PendingDomainOps} that need to be performed on this domain.
class Domain
  NAMESPACE_MAX_LENGTH = 16 unless defined? NAMESPACE_MAX_LENGTH
  NAMESPACE_MIN_LENGTH = 1 unless defined? NAMESPACE_MIN_LENGTH

  # This is the current regex for validations for new domains 
  DOMAIN_NAME_REGEX = /\A[A-Za-z0-9]+\z/
  # This is the regex that ensures backward compatibility for fetches
  DOMAIN_NAME_COMPATIBILITY_REGEX = DOMAIN_NAME_REGEX
  
  include Mongoid::Document
  include Mongoid::Timestamps
  alias_method :mongoid_save, :save

  field :namespace, type: String
  field :canonical_namespace, type: String
  field :env_vars, type: Array, default: []
  embeds_many :system_ssh_keys, class_name: SystemSshKey.name
  belongs_to :owner, class_name: CloudUser.name
  field :user_ids, type: Array, default: []
  has_many :applications, class_name: Application.name, dependent: :restrict
  embeds_many :pending_ops, class_name: PendingDomainOps.name
  
  index({:canonical_namespace => 1}, {:unique => true})
  index({:owner_id => 1})
  index({:user_ids => 1})
  create_indexes
  
  validates :namespace,
    presence: {message: "Namespace is required and cannot be blank."},
    format:   {with: DOMAIN_NAME_REGEX, message: "Invalid namespace. Namespace must only contain alphanumeric characters."},
    length:   {maximum: NAMESPACE_MAX_LENGTH, minimum: NAMESPACE_MIN_LENGTH, message: "Must be a minimum of #{NAMESPACE_MIN_LENGTH} and maximum of #{NAMESPACE_MAX_LENGTH} characters."},
    blacklisted: {message: "Namespace is not allowed.  Please choose another."}
  def self.validation_map
    {namespace: 106}
  end
  
  def initialize(attrs = nil, options = nil)
    super
    self.user_ids << owner._id if owner
  end
  
  def save(options = {})
    notify = !self.persisted?
    res = mongoid_save(options)
    notify_observers(:domain_create_success) if notify
    res
  end

  # Setter for domain namespace - sets the namespace and the canonical_namespace
  def namespace=(domain_name)
    self.canonical_namespace = domain_name.downcase
    super 
  end
  
  # Change the namespace for this Domain and all applications under it. 
  # The namespace update happens in 2 steps:
  #   1. Add the new namespace to all applications
  #   2. Remove the old namespace from all applications. See {#complete_namespace_update}
  #
  # == Parameters:
  #   new_namespace::
  #   The new namespace to use for the domain
  #
  # == Returns:
  #   The domain operation which tracks the first step of the update.
  def update_namespace(new_namespace)
    if Application.with(consistency: :strong).where(domain_id: self._id).count > 0
      raise OpenShift::UserException.new("Domain contains applications. Delete applications first before changing the domain namespace.", 128)
    end
    if Domain.with(consistency: :strong).where(canonical_namespace: new_namespace).count > 0 
      raise OpenShift::UserException.new("Namespace '#{new_namespace}' is already in use. Please choose another.", 103, "id") 
    end
    old_ns = namespace
    self.namespace = new_namespace
    self.save
    notify_observers(:domain_update_success)
    #pending_op = PendingDomainOps.new(op_type: :update_namespace, arguments: {"old_ns" => old_ns, "new_ns" => new_namespace}, parent_op: nil, on_apps: applications, on_completion_method: :complete_namespace_update, state: "init")
    #self.pending_ops.push pending_op
    #self.run_jobs
  end

  # Completes the second step of the namespace update. See {#update_namespace}
  #
  # == Parameters:
  #   op::
  #   The namespace update operation created in step 1.
  #
  # == Returns:
  #   The domain operation which tracks the second step of the update.
  def complete_namespace_update(op)
    pending_op = PendingDomainOps.new(op_type: :complete_namespace_update, arguments: {"old_ns" => op.arguments["old_ns"], "new_ns" => op.arguments["new_ns"]}, parent_op: nil, on_apps: op.on_apps, state: "init")
    self.pending_ops.push pending_op
    self.run_jobs
    notify_observers(:domain_update_success)
  end
  
  # Adds a user to the access list for this domain.
  #
  # == Parameters:
  # user::
  #  The user to add to the access list for this domain.
  def add_user(user)
    unless self.user_ids.include? user._id
      self.user_ids.push user._id
      self.save
      if self.applications.count > 0
        pending_op = PendingDomainOps.new(op_type: :add_user, arguments: {user_id: user._id}, parent_op: nil, on_apps: applications)
        self.pending_ops.push pending_op
        self.run_jobs
      end
    end
  end
  
  # Removes a user from the access list for this domain.
  #
  # == Parameters:
  # user::
  #  The user to remove from the access list for this domain.
  def remove_user(user)
    if self.user_ids.delete user._id
      self.save
      if self.applications.count > 0
        pending_op = PendingDomainOps.new(op_type: :remove_user, arguments: {user_id: user._id}, parent_op: nil, on_apps: applications)
        self.pending_ops.push pending_op
        self.run_jobs
      end
    end
  end
  
  # Support operation to add additional ssh keys for a user
  #
  # == Parameters:
  # user_id::
  #   The ID of the user who owns the ssh key
  # key_attr::
  #   SSH key attributes
  # pending_parent_op::
  #   Parent operation which tracks the key additions
  #
  # == Returns:
  #  The domain operation which tracks the sshkey addition
  def add_ssh_key(user_id, ssh_key, pending_parent_op)
    return if pending_ops.where(parent_op_id: pending_parent_op._id).count > 0
    if((owner._id == user_id || user_ids.include?(user_id)) && self.applications.count > 0)
      self.pending_ops.push(PendingDomainOps.new(op_type: :add_ssh_key, arguments: { "user_id" => user_id, "key_attrs" => [ssh_key.attributes] }, parent_op_id: pending_parent_op._id, on_apps: self.applications, state: "init"))
      self.run_jobs
    else
      pending_parent_op.child_completed(self) if pending_parent_op
    end
  end
  
  # Support operation to remove specific ssh keys for a user
  #
  # == Parameters:
  # user_id::
  #   The ID of the user who owns the ssh key
  # key_attr::
  #   SSH key attributes
  # pending_parent_op::
  #   Parent operation which tracks the key removals
  #
  # == Returns:
  #  The domain operation which tracks the sshkey removal
  def remove_ssh_key(user_id, ssh_key, pending_parent_op)
    return if pending_ops.where(parent_op_id: pending_parent_op._id).count > 0    
    if(self.applications.count > 0)
      self.pending_ops.push PendingDomainOps.new(op_type: :delete_ssh_key, arguments: { "user_id" => user_id, "key_attrs" => [ssh_key.attributes] }, parent_op_id: pending_parent_op._id, on_apps: self.applications, state: "init")
      self.run_jobs
    else
      pending_parent_op.child_completed(self) if pending_parent_op
    end
  end
  
  def add_system_ssh_keys(ssh_keys)
    keys_attrs = ssh_keys.map{|k| k.attributes.dup}
    pending_op = PendingDomainOps.new(op_type: :add_domain_ssh_keys, arguments: { "keys_attrs" => keys_attrs }, on_apps: applications, created_at: Time.now, state: "init")
    Domain.where(_id: self.id).update_all({ "$push" => { pending_ops: pending_op.serializable_hash }, "$pushAll" => { system_ssh_keys: keys_attrs }})
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
    Domain.where(_id: self.id).update_all({ "$push" => { pending_ops: pending_op.serializable_hash }, "$pullAll" => { system_ssh_keys: keys_attrs }})
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
    Domain.where(_id: self.id).update_all({ "$push" => { pending_ops: pending_op.serializable_hash }, "$pushAll" => { env_vars: variables }})

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
    Domain.where(_id: self.id).update_all({ "$push" => { pending_ops: pending_op.serializable_hash }, "$pullAll" => { env_vars: variables }})
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
        retval = Domain.with(consistency: :strong).where({ "_id" => self._id, "pending_ops.#{op_index}._id" => op._id, "pending_ops.#{op_index}.state" => "init" }).update({"$set" => { "pending_ops.#{op_index}.state" => "queued" }})
        
        unless retval["updatedExisting"]
          self.with(consistency: :strong).reload
          next
        end

        case op.op_type
        when :add_user
          user = nil
          begin
            user = CloudUser.find(op.arguments["user_id"])
          rescue Mongoid::Errors::DocumentNotFound
            #ignore
          end
          op.pending_apps.each { |app| app.add_ssh_keys(user._id, user.ssh_keys, op) } if user
        when :remove_user
          user = nil
          begin
            user = CloudUser.find(op.arguments["user_id"])
          rescue Mongoid::Errors::DocumentNotFound
            #ignore
          end
          op.pending_apps.each { |app| app.remove_ssh_keys(user._id, user.ssh_keys, op) } if user
        when :add_ssh_key
          ssh_keys = op.arguments["key_attrs"].map{|k| UserSshKey.new.to_obj(k)}
          op.pending_apps.each { |app| app.add_ssh_keys(op.arguments["user_id"], ssh_keys, op) }
        when :delete_ssh_key
          ssh_keys = op.arguments["key_attrs"].map{|k| UserSshKey.new.to_obj(k)}
          op.pending_apps.each { |app| app.remove_ssh_keys(op.arguments["user_id"], ssh_keys, op) }
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
        when :update_namespace
          op.pending_apps.each { |app| app.update_namespace(op.arguments["old_ns"], op.arguments["new_ns"], op) }
        when :complete_namespace_update
          op.pending_apps.each { |app|
            app.complete_update_namespace(op.arguments["old_ns"], op.arguments["new_ns"], op) 
          }
        end

        # reloading the op reloads the domain and then incorrectly reloads (potentially)
        # the op based on its position within the pending_ops list
        # hence, reloading the domain, and then fetching the op using the op_id stored earlier
        self.with(consistency: :strong).reload
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
