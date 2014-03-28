# Class to represent pending operations that need to occur for the {CloudUser}
# @!attribute [r] state
#   @return [Symbol] Operation state. One of init, queued or completed
# @!attribute [r] completed_domain_ids
#   @return [Array] Ids for domains on which this operation has been completed
# @!attribute [r] on_completion_method
#   @return [Symbol] Optional method to call on the User object after operation has completed
class PendingUserOp
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  embedded_in :pending_user_op_group, class_name: PendingUserOpGroup.name

  field :state, type: Symbol, :default => :init
  field :prereq, type: Array
  has_and_belongs_to_many :completed_domains, class_name: Domain.name, inverse_of: nil
  field :on_completion_method, type: Symbol

  def pending_domains
    (user.domains - completed_domains)
  end

  def prereq
    self.attributes["prereq"] || []
  end

  # this method needs to be implemented by the subclass
  def execute
    Rails.logger.debug "Execution not implemented: #{self.class.to_s}"
  end

  # this method needs to be implemented by the subclass
  def rollback
    Rails.logger.debug "Rollback not implemented: #{self.class.to_s}"
  end

  # Returns true if all domains have been processed
  def completed?
    (self.state == :completed) || (pending_domains.length == 0)
  end

  def close_op
    if completed?
      user.send(on_completion_method, self) unless on_completion_method.nil?
    end
  end

  # Callback from {PendingDomainOps} to indicate that a domain has been processed
  def child_completed(domain)
    failure_message = "Failed to add domain #{domain._id.to_s} to the completed_domains for pending_op #{self._id.to_s} for user #{user.login}"
    updated_op = update_with_retries(5, failure_message) do |current_user, current_op_group, current_op, op_group_index, op_index|
      CloudUser.where({ "_id" => current_user._id, "pending_op_groups.#{op_group_index}._id" => current_op_group._id, "pending_op_groups.#{op_group_index}.pending_ops.#{op_index}._id" => current_op._id }).update({"$addToSet" => { "pending_op_groups.#{op_group_index}.pending_ops.#{op_index}.completed_domain_ids" => domain._id }})
    end

    reloaded_user = CloudUser.find_by(_id: user._id)
    reloaded_user.pending_op_groups.each do |op_group|
      if op_group.pending_ops.where(_id: self._id).exists?
        reloaded_op = op_group.pending_ops.find_by(_id: self._id)
        reloaded_op.set_state(:completed) if reloaded_op.completed?
        break
      end
    end
  end

  # the new_state needs to be a symbol
  def set_state(new_state)
    failure_message = "Failed to set pending_op #{self._id.to_s} state to #{new_state.to_s} for user #{user.login}"
    updated_op = update_with_retries(5, failure_message) do |current_user, current_op_group, current_op, op_group_index, op_index|
      CloudUser.where({ "_id" => current_user._id, "pending_op_groups.#{op_group_index}._id" => current_op_group._id, "pending_op_groups.#{op_group_index}.pending_ops.#{op_index}._id" => current_op._id }).update({"$set" => { "pending_op_groups.#{op_group_index}.pending_ops.#{op_index}.state" => new_state }})
    end

    # set the state in the object in mongoid memory for access by the caller
    self.state = updated_op.state
  end

  def update_with_retries(num_retries, failure_message, &block)
    retries = 0
    success = false

    current_op = self
    current_op_group = self.pending_user_op_group
    current_user = self.user

    # find the op index and do an atomic update
    op_group_index = current_user.pending_op_groups.index(current_op_group) 
    op_index = current_user.pending_op_groups[op_group_index].pending_ops.index(current_op)

    while retries < num_retries
      retval = block.call(current_user, current_op_group, current_op, op_group_index, op_index)
      if retval["updatedExisting"]
        success = true
        break
      end

      # the op needs to be reloaded to find the updated index
      current_user = CloudUser.find_by(_id: current_user._id)
      current_op_group = current_user.pending_op_groups.find_by(_id: current_op_group._id)
      op_group_index = current_user.pending_op_groups.index(current_op_group)
      current_op = current_user.pending_op_groups[op_group_index].pending_ops.find_by(_id: current_op._id)
      op_index = current_user.pending_op_groups[op_group_index].pending_ops.index(current_op)
      retries += 1

    end

    # log the details in case we cannot update the pending_op
    unless success
      Rails.logger.error(failure_message)
    end
    return current_op
  end

  def to_log_s
    "#{self.class}"
  end

  def user
    pending_user_op_group.cloud_user
  end

end
