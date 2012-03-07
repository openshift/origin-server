#
# The REST API model object representing a cartridge instance.
#
class Cartridge < RestApi::Base
  schema do
    string :name, 'type'
  end

  custom_id :name

  belongs_to :application

  self.prefix = "#{RestApi::Base.site.path}domains/:domain_name/applications/:application_name/"

  def type
    @attributes[:type]
  end

  def type=(type)
    @attributes[:type]=type
  end

  def application_name=(id)
    self.prefix_options[:application_name] = id
  end

  def domain_name=(id)
    self.prefix_options[:domain_name] = id
  end

  def application=(application)
    self.application_name = application.id
    self.domain_name = application.domain_name
  end
end
