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
# @!attribute [r] on_apps
#   @return [Array[Moped::BSON::ObjectId]] IDs of the {Application} that are part of this operation.
# @!attribute [r] completed_apps
#   @return [Array[Moped::BSON::ObjectId]] IDs of the {Application} that have completed their sub-tasks.
#     @see {PendingDomainOps#child_completed}
# @!attribute [r] on_completion_method
#   @return [Symbol] Method to call on the {Domain} once this operation is complete.
class PendingDomainOps
  include Mongoid::Document
  include Mongoid::Timestamps
  
  embedded_in :domain, class_name: Domain.name
  
  field :op_type,   type: Symbol
  field :arguments, type: Hash
  field :parent_op_id, type: Moped::BSON::ObjectId
  field :state,    type: Symbol
  has_and_belongs_to_many :on_apps, class_name: Application.name, inverse_of: nil
  has_and_belongs_to_many :completed_apps, class_name: Application.name, inverse_of: nil
  field :on_completion_method, type: Symbol
  
  def pending_apps
    pending_apps = on_apps - completed_apps
    pending_apps
  end
  
  def completed?
    (self.state == :completed) || ((on_apps.length - completed_apps.length) == 0)
  end
  
  def close_op
    if completed?
      if not parent_op_id.nil?
        user = CloudUser.find_by(_id: self.domain.owner_id)
        parent_op = user.pending_ops.find_by(_id: self.parent_op_id)
        parent_op.child_completed(self.domain)
      end
      domain.send(on_completion_method, self) unless on_completion_method.nil?
    end
  end

  def child_completed(app)
    retries = 0
    success = false

    # find the op index and do an atomic update
    op_index = self.domain.pending_ops.index(self) 
    while retries < 5
      retval = Domain.where({ "_id" => self.domain._id, "pending_ops.#{op_index}._id" => self._id }).update({"$addToSet" => { "pending_ops.#{op_index}.completed_app_ids" => app._id }})

      # the op needs to be reloaded to either set the :state or to find the updated index
      reloaded_domain = Domain.find_by(_id: self.domain._id)
      current_op = reloaded_domain.pending_ops.find_by(_id: self._id)
      if retval["updatedExisting"]
        current_op.set(:state, :completed) if current_op.completed?
        success = true
        break
      else
        op_index = reloaded_domain.pending_ops.index(current_op)
        retries += 1
      end
    end
    
    # log the details in case we cannot update the pending_op
    unless success
      Rails.logger.error "Failed to add application #{app._id} to the completed_apps for pending_op #{self._id} for domain #{self.domain.namespace}"
    end  
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
    s_hash
  end
end
