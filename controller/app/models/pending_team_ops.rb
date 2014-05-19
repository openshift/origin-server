# Class to represent pending operations that need to occur for the {Team}
# @!attribute [rw] team
#   @return [Team] The {Team} that operation needs to be applied on.
# @!attribute [r] op_type
#   @return [Symbol] Operation type.
# @!attribute [rw] state
#   @return [Symbol] Operation state. One of init, queued or completed.
# @!attribute [r] arguments
#   @return [Hash] Arguments hash.
# @!attribute [r] on_completion_method
#   @return [Symbol] Method to call on the {Team} once this operation is complete.
class PendingTeamOps
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :team, class_name: Team.name

  field :state, type: Symbol, :default => :init
  field :queued_at, type: Integer, :default => 0
  field :on_completion_method, type: Symbol

  def completed?
    (self.state == :completed)
  end

  def close_op
    if completed?
      team.send(on_completion_method, self) unless on_completion_method.nil?
    end
  end

  # the new_state needs to be a symbol
  def set_state(new_state)
    failure_message = "Failed to set pending_op #{self._id.to_s} state to #{new_state.to_s} for team #{self.team.name}"
    updated_op = update_with_retries(5, failure_message) do |current_team, current_op, op_index|
      Team.where({ "_id" => current_team._id, "pending_ops.#{op_index}._id" => current_op._id }).update({"$set" => { "pending_ops.#{op_index}.state" => new_state }})
    end

    # set the state in the object in mongoid memory for access by the caller
    self.state = updated_op.state
  end

  def update_with_retries(num_retries, failure_message, &block)
    retries = 0
    success = false

    current_op = self
    current_team = self.team

    # find the op index and do an atomic update
    op_index = current_team.pending_ops.index(current_op) 
    while retries < num_retries
      retval = block.call(current_team, current_op, op_index)

      # the op needs to be reloaded to find the updated index
      current_team = Team.find_by(_id: current_team._id)
      current_op = current_team.pending_ops.find_by(_id: current_op._id)
      op_index = current_team.pending_ops.index(current_op)
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
