#
# The REST API model object representing a cartridge instance.
#
class Cartridge < RestApi::Base
  schema do
    string :name, :type
  end

  custom_id :name

  alias_attribute :application_name, :application_id

  belongs_to :application
  
  self.prefix = "#{RestApi::Base.site.path}/domains/:domain_name/applications/:application_name/"
  
  def application
    Application.find application_name, :as => as
  end

  def application=(application)
    self.application_id = application.is_a?(String) ? application : application.namespace
  end

  def application_id=(id)
    self.prefix_options[:application_name] = id
    super
  end

end