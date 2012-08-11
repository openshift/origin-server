class PendingDomainOps
  include Mongoid::Document
  embedded_in :domain, class_name: Domain.name
  
  field :op_type,   type: String
  field :arguments, type: Hash
  belongs_to :parent_op, class_name: PendingDomainOps.name  
  
  def parent_op
    self.domain.owner.pending_ops.find(self.parent_op_id)
  end
end