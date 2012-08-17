# Represents a connection between components of the application.
# @!attribute [r] from_comp_inst_id
#   @return [Moped::BSON::ObjectId] ID of the publishing {ComponentInstance}
# @!attribute [r] to_comp_inst_id
#   @return [Moped::BSON::ObjectId] ID of the subscribing {ComponentInstance}
# @!attribute [r] from_connector_name
#   @return [String] Name of the connector hook for the publishing {ComponentInstance}
# @!attribute [r] to_connector_name
#   @return [String] Name of the connector hook for the subscribing {ComponentInstance}  
# @!attribute [r] connection_type
#   @return [String] The connection type
class ConnectionInstance
  include Mongoid::Document
  embedded_in :application, class_name: Application.name
  field :from_comp_inst_id, type: Moped::BSON::ObjectId
  field :to_comp_inst_id, type: Moped::BSON::ObjectId
  field :from_connector_name, :type => String
  field :to_connector_name, :type => String
  field :connection_type, :type => String  
end
