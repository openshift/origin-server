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

  attr_accessor :from_comp_inst_id, :to_comp_inst_id, :from_connector_name, :to_connector_name, :connection_type, :_id

  def initialize(from_comp_inst_id, to_comp_inst_id, from_connector_name, to_connector_name, connection_type)
    self.from_comp_inst_id = from_comp_inst_id
    self.to_comp_inst_id = to_comp_inst_id
    self.from_connector_name = from_connector_name
    self.to_connector_name = to_connector_name
    self.connection_type = connection_type
    self._id = BSON::ObjectId.new
  end

  def to_hash(app)
    {
      "from_comp_inst" => app.component_instances.find(from_comp_inst_id).to_hash,
      "to_comp_inst" => app.component_instances.find(to_comp_inst_id).to_hash,
      "from_connector_name" => from_connector_name,
      "to_connector_name" => to_connector_name,
      "connection_type" => connection_type
    }
  end
end
