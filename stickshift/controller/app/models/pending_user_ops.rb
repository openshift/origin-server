class PendingUserOps
  include Mongoid::Document
  embedded_in :cloud_user, class_name: CloudUser.name
  
  field :op_type,   type: String
  field :arguments, type: Hash
end