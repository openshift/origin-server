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
  
  include Mongoid::Document
  include Mongoid::Timestamps

  field :namespace, type: String
  field :canonical_namespace, type: String
  field :env_vars, type: Array, default: []
  embeds_many :system_ssh_keys, class_name: SystemSshKey.name
  belongs_to :owner, class_name: CloudUser.name
  field :user_ids, type: Array, default: []
  has_many :applications, class_name: Application.name, dependent: :restrict
  embeds_many :pending_ops, class_name: PendingDomainOps.name
  
  index({:namespace => 1}, {:unique => true})
  create_indexes
  
  validates :namespace,
    presence: {message: "Namespace is required and cannot be blank."},
    format:   {with: /\A[A-Za-z0-9]+\z/, message: "Invalid namespace. Namespace must only contain alphanumeric characters."},
    length:   {maximum: NAMESPACE_MAX_LENGTH, minimum: NAMESPACE_MIN_LENGTH, message: "Must be a minimum of #{NAMESPACE_MIN_LENGTH} and maximum of #{NAMESPACE_MAX_LENGTH} characters."},
    blacklisted: {message: "Namespace is not allowed.  Please choose another."}
  def self.validation_map
    {namespace: 106}
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
    old_ns = namespace
    set(:namespace, new_namespace)
    pending_op = PendingDomainOps.new(op_type: :update_namespace, arguments: {"old_ns" => old_ns, "new_ns" => new_namespace}, parent_op: nil, on_apps: applications, on_completion_method: :complete_namespace_update, state: "init")
    self.pending_ops.push pending_op
    self.run_jobs
    pending_op.delete
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
    pending_op.delete
  end
  
  # Adds a user to the access list for this domain.
  #
  # == Parameters:
  # user::
  #  The user to add to the access list for this domain.
  #
  # == Returns:
  #  The domain operation which tracks the user addition.
  def add_user(user)
    self.user_ids.push user._id
    pending_op = PendingDomainOps.new(op_type: :add_user, arguments: {user: user._id}, parent_op: nil, on_apps: applications)
    self.pending_ops.push pending_op
    pending_op.on_apps.each do |app|
      app.add_ssh_keys(user, user.ssh_keys, pending_op)
    end
    pending_op
  end
  
  # Removes a user from the access list for this domain.
  #
  # == Parameters:
  # user::
  #  The user to remove from the access list for this domain.
  #
  # == Returns:
  #  The domain operation which tracks the user removal.
  def remove_user(user)
    self.user_ids.push user._id
    pending_op = PendingDomainOps.new(op_type: :remove_user, arguments: {user: user._id}, parent_op: nil, on_apps: applications)
    self.pending_ops.push pending_op
    pending_op.on_apps.each do |app|
      app.remove_ssh_keys(user, user.ssh_keys, pending_op)
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
  def add_ssh_key(user_id, key_attr, pending_parent_op)
    return if pending_ops.where(parent_op_id: pending_parent_op._id).count > 0
    if((owner._id == user_id || user_ids.include?(user_id)) && self.applications.count > 0)
      self.pending_ops.push(PendingDomainOps.new(op_type: :add_ssh_key, arguments: { "user_id" => user_id, "key_attrs" => [key_attr] }, parent_op_id: pending_parent_op._id, on_apps: self.applications, state: "init"))
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
  def remove_ssh_key(user_id, key_attr, pending_parent_op)
    return if pending_ops.where(parent_op_id: pending_parent_op._id).count > 0    
    if(self.applications.count > 0)
      self.pending_ops.push PendingDomainOps.new(op_type: :delete_ssh_key, arguments: { "user_id" => user_id, "key_attrs" => [key_attr] }, parent_op_id: pending_parent_op._id, on_apps: self.applications, state: "init")
      self.run_jobs
    else
      pending_parent_op.child_completed(self) if pending_parent_op
    end
  end
  
  def add_system_ssh_keys(keys_attrs)
    pending_op = PendingDomainOps.new(op_type: :add_domain_ssh_keys, arguments: { "keys_attrs" => keys_attrs }, on_apps: applications, created_at: Time.now, state: "init")
    Domain.where(_id: self.id).update_all({ "$push" => { pending_ops: pending_op.serializable_hash }, "$pushAll" => { system_ssh_keys: keys_attrs }})
  end

  def remove_system_ssh_keys(key_names)
    pending_op = PendingDomainOps.new(op_type: :delete_domain_ssh_keys, arguments: {"keys_attrs" => keys_to_remove}, on_apps: applications, created_at: Time.now, state: "init")
    Domain.where(_id: self.id).update_all({ "$push" => { pending_ops: pending_op.serializable_hash }, "$pullAll" => { system_ssh_keys: keys_attrs }})
  end

  def add_env_variables(variables)
    pending_op = PendingDomainOps.new(op_type: :add_env_variables, arguments: {"variables" => variables}, on_apps: applications, created_at: Time.now, state: "init")
    Domain.where(_id: self.id).update_all({ "$push" => { pending_ops: pending_op.serializable_hash }, "$pushAll" => { env_vars: variables }})
  end

  def remove_env_variables(variables)
    pending_op = PendingDomainOps.new(op_type: :remove_env_variables, arguments: {"variables" => variables}, on_apps: applications, created_at: Time.now, state: "init")
    Domain.where(_id: self.id).update_all({ "$push" => { pending_ops: pending_op.serializable_hash }, "$pullAll" => { env_vars: variables }})
  end

  # Runs all jobs in "init" phase and stops at the first failure.
  #
  # == Returns:
  # True on success or false on failure
  def run_jobs
    begin
      ops = pending_ops.where(state: "init")
      ops.each do |op|
        case op.op_type
        when :add_ssh_key
          op.pending_apps.each { |app| app.add_ssh_keys(op.arguments["user_id"], op.arguments["key_attrs"], op) }
        when :delete_ssh_key
          op.pending_apps.each { |app| app.remove_ssh_keys(op.arguments["user_id"], op.arguments["key_attrs"], op) }
        when :add_domain_ssh_keys
          op.pending_apps.each { |app| app.add_ssh_keys(nil, op.arguments["keys_attrs"], op) }
        when :delete_domain_ssh_keys
          op.pending_apps.each { |app| app.remove_ssh_keys(op.arguments["keys_attrs"], op) }
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
        begin
          self.pending_ops.find_by(_id: op._id, :state.ne => :completed).set(:state, :queued)
          op.reload
          op.close_op
        rescue Mongoid::Errors::DocumentNotFound
          #ignore. Op state is completed
        end
      end
      true
    rescue Exception => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace
      raise e
    end
  end
end
