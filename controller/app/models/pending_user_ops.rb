# Class to represent pending operations that need to occur for the {CloudUser}
# @!attribute [r] cloud_user
#   @return [CloudUser] The {CloudUser} that operation needs to be applied on.
# @!attribute [r] op_type
#   @return [Symbol] Operation type.
# @!attribute [r] state
#   @return [Symbol] Operation state. One of init, queued or completed
# @!attribute [r] arguments
#   @return [Hash] Arguments hash
# @!attribute [r] on_domain_ids
#   @return [Array] Ids for domains on which this operation needs to be run
# @!attribute [r] completed_domain_ids
#   @return [Array] Ids for domains on which this operation has been completed
# @!attribute [r] on_completion_method
#   @return [Symbol] Optional method to call on the User object after operation has completed
class PendingUserOps
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  embedded_in :cloud_user, class_name: CloudUser.name
  field :state, type: Symbol, :default => :init
  has_and_belongs_to_many :on_domains, class_name: Domain.name, inverse_of: nil
  has_and_belongs_to_many :completed_domains, class_name: Domain.name, inverse_of: nil
  field :on_completion_method, type: Symbol

  # List of domains that are still pending
  #
  # == Returns:
  # Array of {Domain}s
  def pending_domains
    pending_domains = on_domains - completed_domains
    pending_domains
  end

  # Returns true if all domains have been processed
  def completed?
    self.state == :completed
  end

  def close_op
    if completed?
      cloud_user.user.send(on_completion_method, self) unless on_completion_method.nil?
    end
  end

  # Callback from {PendingDomainOps} to indicate that a domain has been processed
  def child_completed(domain)
    failure_message = "Failed to add domain #{domain._id.to_s} to the completed_domains for pending_op #{self._id.to_s} for user #{self.cloud_user.login}"
    update_with_retries(5, failure_message) do |current_user, current_op, op_index|
      CloudUser.where({ "_id" => current_user._id, "pending_ops.#{op_index}._id" => current_op._id }).update({"$addToSet" => { "pending_ops.#{op_index}.completed_domain_ids" => domain._id }})
    end

    reloaded_user = CloudUser.find_by(_id: self.cloud_user._id)
    reloaded_op = reloaded_user.pending_ops.find_by(_id: self._id)
    reloaded_op.set_state(:completed) if reloaded_op.completed?
  end

  # the new_state needs to be a symbol
  def set_state(new_state)
    failure_message = "Failed to set pending_op #{self._id.to_s} state to #{new_state.to_s} for user #{self.cloud_user.login}"
    updated_op = update_with_retries(5, failure_message) do |current_user, current_op, op_index|
      CloudUser.where({ "_id" => current_user._id, "pending_ops.#{op_index}._id" => current_op._id }).update({"$set" => { "pending_ops.#{op_index}.state" => new_state }})
    end

    # set the state in the object in mongoid memory for access by the caller
    self.state = updated_op.state
  end

  def update_with_retries(num_retries, failure_message, &block)
    retries = 0
    success = false

    current_op = self
    current_user = self.cloud_user

    # find the op index and do an atomic update
    op_index = current_user.pending_ops.index(current_op) 
    while retries < num_retries
      retval = block.call(current_user, current_op, op_index)

      # the op needs to be reloaded to find the updated index
      current_user = CloudUser.find_by(_id: current_user._id)
      current_op = current_user.pending_ops.find_by(_id: current_op._id)
      op_index = current_user.pending_ops.index(current_op)
      retries += 1

      if retval["updatedExisting"]
        success = true
        break
      end
    end

    # log the details in case we cannot update the pending_op
    unless success
      Rails.logger.error(failure_message)
    end
    return current_op
  end
end
