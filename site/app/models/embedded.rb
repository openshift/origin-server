#
# The REST API model object representing an embedded cartridge name attached to an application.
#
class Embedded < RestApi::Base
  
  self.collection_name = 'embedded'
  
  schema do
    string :name
  end

  def initialize(attributes={}, persisted=false)
    puts 'EMBEDDED GOT THE HELL CREATED!!!'
    attributes.each do |attribute|
      puts attribute
    end
    @persisted = persisted
    @as = attributes[:as]
    attributes.delete :as
    # super attributes
  end
  
  belongs_to :application
end
