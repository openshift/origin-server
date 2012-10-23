class ConnectionEndpoint < OpenShift::Model
  attr_accessor :from_comp_inst, :to_comp_inst, :from_connector, :to_connector
  
  def initialize(from_comp, to_comp, pub, sub)
    self.from_comp_inst = from_comp.name
    self.to_comp_inst = to_comp.name
    self.from_connector = pub
    self.to_connector = sub
  end
end
