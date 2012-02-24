#
# The REST API model object representing a cartridge instance.
#
class Cartridge < RestApi::Base
  schema do
    string :name, :type
  end

  self.prefix = "#{RestApi::Base.site.path}/domains/:domain_name/applications/:application_name/"
  
  belongs_to :application
  
end