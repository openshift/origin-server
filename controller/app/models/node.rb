# Represents an OpenShift Node 
# @!attribute [r] name
#   @return [String] Name of the node.
# @!attribute [r] location 
#   @return [String] Location of node (i.e. host:port)
class Node
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :location, type: String 

  index({:name => 1}, {:unique => true})

  create_indexes

  def self.find_by_name(name)
    return Node.where(name: name)[0]
  end

end
