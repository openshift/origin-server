class ComponentInstance
  include Mongoid::Document
  embedded_in :application
  
  field :cartridge_name, type: String
  field :component_name, type: String
  field :component_properties, type: Hash, default: {}
  field :group_instance_name, type: Moped::BSON::ObjectId
end
