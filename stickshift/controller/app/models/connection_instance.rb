class ConnectionInstance
  include Mongoid::Document
  embedded_in :application, class_name: Application.name
  embeds_one :from_comp_inst, :class_name => ComponentRef.name
  field :from_connector_name, :type => String
  embeds_one :to_comp_inst,   :class_name => ComponentRef.name
  field :to_connector_name, :type => String
  field :connection_type, :type => String  
end
