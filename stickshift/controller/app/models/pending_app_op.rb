# Class to represent pending operations that need to occur for the {Application}
# @!attribute [r] application
#   @return [Application] {Application} that this operation needs to be performed on.
# @!attribute [r] op_type
#   @return [Symbol] Operation type
# @!attribute [r] state
#   @return [Symbol] Operation state. One of init, queued or completed
# @!attribute [r] arguments
#   @return [Hash] Arguments hash
# @!attribute [r] retry_count
#   @return [Integer] Number of times this operation has been attempted
class PendingAppOp
  include Mongoid::Document
  embedded_in :pending_app_op_group, class_name: PendingAppOpGroup.name
  field :op_type,           type: Symbol
  field :state,             type: Symbol,   default: :init
  field :args,              type: Hash
  field :prereq,            type: Array
  field :retry_count,       type: Integer,  default: 0
  field :retry_rollback_op, type: Moped::BSON::ObjectId
  field :saved_values,      type: Hash, default: []

  def args
    self.attributes["args"] || {}
  end

  def prereq
    self.attributes["prereq"] || []
  end

  # Sets the [PendingDomainOps] Domain level operation that spawned this operation.
  #
  # == Parameters:
  # op::
  #   The {PendingDomainOps} object.
  def parent_op=(op)
    self.parent_op_id = op._id unless op.nil?
  end
  
  # @return [PendingDomainOps] Domain level operation that spawned this operation.  
  def parent_op
    self.application.domain.pending_ops.find(self.parent_op_id) unless parent_op_id.nil?
  end
  
  # Marks the operation as completed on the parent operation.
  def completed
    self.state = :completed
    self.save
    parent_op.child_completed(application) unless parent_op_id.nil?
  end
end