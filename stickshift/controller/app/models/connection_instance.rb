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
  
  def to_hash
    {
      "from_comp_inst" => self.application.component_instances.find(from_comp_inst_id).to_hash,
      "to_comp_inst" => self.application.component_instances.find(to_comp_inst_id).to_hash,
      "from_connector_name" => from_connector_name,
      "to_connector_name" => to_connector_name,
      "connection_type" => connection_type
    }
  end
end
