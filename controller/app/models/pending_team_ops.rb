# Class to represent pending operations that need to occur for the {Team}
# @!attribute [rw] team
#   @return [Team] The {Team} that operation needs to be applied on.
# @!attribute [r] op_type
#   @return [Symbol] Operation type.
# @!attribute [rw] state
#   @return [Symbol] Operation state. One of init, queued or completed.
# @!attribute [r] arguments
#   @return [Hash] Arguments hash.
# @!attribute [rw] parent_op_id
#   @return [Moped::BSON::ObjectId] ID of the {PendingUserOps} operation that this operation is part of.
# @!attribute [r] on_domains
#   @return [Array[Moped::BSON::ObjectId]] IDs of the {Domain} that are part of this operation.
# @!attribute [r] completed_domains
#   @return [Array[Moped::BSON::ObjectId]] IDs of the {Domain} that have completed their sub-tasks.
#     @see {PendingTeamOps#child_completed}
# @!attribute [r] on_completion_method
#   @return [Symbol] Method to call on the {Team} once this operation is complete.
class PendingTeamOps
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :team, class_name: Team.name

  field :parent_op_id, type: Moped::BSON::ObjectId
  field :state, type: Symbol, :default => :init
  has_and_belongs_to_many :on_domains, class_name: Domain.name, inverse_of: nil
  has_and_belongs_to_many :completed_domains, class_name: Domain.name, inverse_of: nil
  field :on_completion_method, type: Symbol

  def pending_domains
    pending_domains = on_domains - completed_domains
    pending_domains
  end

  def completed?
    (self.state == :completed) || ((on_domains.length - completed_domains.length) == 0)
  end

  def close_op
    if completed?
      if not parent_op_id.nil?
        user = CloudUser.find_by(_id: self.team.owner_id)
        parent_op = user.pending_ops.find_by(_id: self.parent_op_id)
        parent_op.child_completed(self.team)
      end
      team.send(on_completion_method, self) unless on_completion_method.nil?
    end
  end

  def child_completed(domain)
    failure_message = "Failed to add domain #{domain._id} to the completed_domains for pending_op #{self._id} for team #{self.team.name}"
    update_with_retries(5, failure_message) do |current_team, current_op, op_index|
      Team.where({ "_id" => current_team._id, "pending_ops.#{op_index}._id" => current_op._id }).update({"$addToSet" => { "pending_ops.#{op_index}.completed_domain_ids" => app._id }})
    end

    reloaded_team = Team.find_by(_id: self.team._id)
    reloaded_op = reloaded_team.pending_ops.find_by(_id: self._id)
    reloaded_op.set_state(:completed) if reloaded_op.completed?
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


  def serializable_hash_with_timestamp
    s_hash = self.serializable_hash
    t = Time.zone.now
    if self.created_at.nil?
      s_hash["created_at"] = t
    end
    if self.updated_at.nil?
      s_hash["updated_at"] = t
    end
    # need to set the _type attribute for MongoId to instantiate the appropriate class 
    s_hash["_type"] = self.class.to_s unless s_hash["_type"]
    s_hash
  end
end
