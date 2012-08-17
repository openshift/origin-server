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
  
  def parent_op
    self.domain.owner.pending_ops.find(self.parent_op_id) unless parent_op_id.nil?
  end
  
  def pending_apps
    pending_apps = on_apps - completed_apps
    pending_apps
  end
  
  def completed?
    self.state == "completed" || (on_apps.length - completed_apps.length)
  end
  
  def child_completed(app)
    completed_apps << app
    if completed?
      self.set(:state, :completed)
      unless on_completion_method.nil?
        domain.send(on_completion_method, self) 
      else
        parent_op.child_completed(domain) unless parent_op.nil?
      end
    end
  end
end