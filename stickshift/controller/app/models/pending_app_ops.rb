# Class to represent pending operations that need to occur for the {Application}
# @!attribute [r] application
#   @return [Application] {Application} that this operation needs to be performed on.
# @!attribute [r] op_type
#   @return [Symbol] Operation type
# @!attribute [r] state
#   @return [Symbol] Operation state. One of init, queued or completed
# @!attribute [r] arguments
#   @return [Hash] Arguments hash
# @!attribute [r] flag_req_change
#   @return [Boolean] True if this operation causes gears or connections to be added or removed
# @!attribute [rw] parent_op_id
#   @return [Moped::BSON::ObjectId] ID of the {PendingDomainOps} operation that this operation is part of
# @!attribute [r] retry_count
#   @return [Integer] Number of times this operation has been attmpted
class PendingAppOps
  include Mongoid::Document
  include Mongoid::Timestamps
  embedded_in :application, class_name: Application.name
  field :op_type,   type: Symbol
  field :state,    type: Symbol, default: :init
  field :args, type: Hash, default: {}
  field :flag_req_change, type: Boolean, default: false
  field :parent_op_id, type: Moped::BSON::ObjectId
  field :retry_count, type: Integer, default: 0

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