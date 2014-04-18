# Class to represent pending operations that need to occur for the {Domain}
# @!attribute [rw] domain
#   @return [Domain] The {Domain} that operation needs to be applied on.
# @!attribute [r] op_type
#   @return [Symbol] Operation type.
# @!attribute [rw] state
#   @return [Symbol] Operation state. One of init, queued or completed.
# @!attribute [r] arguments
#   @return [Hash] Arguments hash.
# @!attribute [rw] parent_op_id
#   @return [Moped::BSON::ObjectId] ID of the {PendingUserOps} operation that this operation is part of.
# @!attribute [r] completed_apps
#   @return [Array[Moped::BSON::ObjectId]] IDs of the {Application} that have completed their sub-tasks.
#     @see {PendingDomainOps#child_completed}
# @!attribute [r] on_completion_method
#   @return [Symbol] Method to call on the {Domain} once this operation is complete.
class PendingDomainOps
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  embedded_in :domain, class_name: Domain.name

  field :parent_op_id, type: Moped::BSON::ObjectId
  field :state, type: Symbol, :default => :init
  field :queued_at, type: Integer, :default => 0
  has_and_belongs_to_many :completed_apps, class_name: Application.name, inverse_of: nil
  field :on_completion_method, type: Symbol

  def initialize(attrs = nil, options = nil)
    parent_opid = nil
    if !attrs.nil? and attrs[:parent_op]
      parent_opid = attrs[:parent_op]._id
      attrs.delete(:parent_op)
    end
    super
    self.parent_op_id = parent_opid
  end

  def pending_apps
    (domain.applications - completed_apps)
  end

  def completed?
    (self.state == :completed) || (pending_apps.length == 0)
  end

  def close_op
    if completed?
      if not parent_op_id.nil?
        user = CloudUser.find_by(_id: self.domain.owner_id)
        user.pending_op_groups.each do |op_group|
          if op_group.pending_ops.where(_id: self.parent_op_id).exists?
            parent_op = op_group.pending_ops.find_by(_id: self.parent_op_id)
            parent_op.child_completed(self.domain)
            break
          end
        end
      end
      domain.send(on_completion_method, self) unless on_completion_method.nil?
    end
  end

  def child_completed(app)
    failure_message = "Failed to add application #{app._id} to the completed_apps for pending_op #{self._id} for domain #{self.domain.namespace}"
    update_with_retries(5, failure_message) do |current_domain, current_op, op_index|
      Domain.where({ "_id" => current_domain._id, "pending_ops.#{op_index}._id" => current_op._id }).update({"$addToSet" => { "pending_ops.#{op_index}.completed_app_ids" => app._id }})
    end

    reloaded_domain = Domain.find_by(_id: self.domain._id)
    reloaded_op = reloaded_domain.pending_ops.find_by(_id: self._id)
    reloaded_op.set_state(:completed) if reloaded_op.completed?
  end

  # the new_state needs to be a symbol
  def set_state(new_state)
    failure_message = "Failed to set pending_op #{self._id.to_s} state to #{new_state.to_s} for domain #{self.domain.namespace}"
    updated_op = update_with_retries(5, failure_message) do |current_domain, current_op, op_index|
      Domain.where({ "_id" => current_domain._id, "pending_ops.#{op_index}._id" => current_op._id }).update({"$set" => { "pending_ops.#{op_index}.state" => new_state }})
    end

    # set the state in the object in mongoid memory for access by the caller
    self.state = updated_op.state
  end

  def update_with_retries(num_retries, failure_message, &block)
    retries = 0
    success = false

    current_op = self
    current_domain = self.domain

    # find the op index and do an atomic update
    op_index = current_domain.pending_ops.index(current_op) 
    while retries < num_retries
      retval = block.call(current_domain, current_op, op_index)

      # the op needs to be reloaded to find the updated index
      current_domain = Domain.find_by(_id: current_domain._id)
      current_op = current_domain.pending_ops.find_by(_id: current_op._id)
      op_index = current_domain.pending_ops.index(current_op)
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
