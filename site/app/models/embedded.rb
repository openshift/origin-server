#
# The REST API model object representing an embedded cartridge name attached to an application.
# This is going to be DEPRECATED on server side, so we will not use it (use /cartridges instead)
#
class Embedded < RestApi::Base
  
  self.collection_name = 'embedded'
  
  def initialize(attributes={}, persisted=false)
  end
  
  belongs_to :application
end
