class Gear
  include Mongoid::Document
  embedded_in :group_instance, class_name: GroupInstance.name
  
  field :server_identity, type: String
  field :uid, type: Integer
end
