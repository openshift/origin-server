class PendingAppOps
  include Mongoid::Document
  embedded_in :application, class_name: Application.name
  
  field :op_type,   type: String
  field :arguments, type: Hash
  belongs_to :parent_op, class_name: PendingDomainOps.name
end