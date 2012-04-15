#
# The REST API model object representing an application instance.
#
class Application < RestApi::Base
  schema do
    string :name, :creation_time
    string :uuid, :domain_id
    string :server_identity
    string :gear_profile
  end

  custom_id :name
  def id #FIXME provided as legacy support for accessing .name via .id
    name
  end
  alias_attribute :domain_name, :domain_id

  has_many :aliases
  has_many :cartridges

  belongs_to :domain
  self.prefix = "#{RestApi::Base.site.path}/domains/:domain_name/"

  # domain_id overlaps with the attribute returned by the server
  def domain_id=(id)
    self.prefix_options[:domain_name] = id
    super
  end

  def domain
    Domain.find domain_name, :as => as
  end

  def domain=(domain)
    self.domain_id = domain.is_a?(String) ? domain : domain.id
  end
  
  def find_cartridge(name)
    Cartridge.find name, { :params => { :domain_name => domain_id, :application_name => self.name }, :as => as}
  end
  
  def cartridges
    Cartridge.find :all, { :params => { :domain_name => domain_id, :application_name => self.name }, :as => as }
  end

  def web_url
    'http://' << url_authority
  end
  def git_url
    "ssh://#{uuid}@#{url_authority}/~/git/#{name}.git/"
  end

  def framework_name
    ApplicationType.find(framework).name rescue framework
  end
  
  # Causes a problem during serialization, application_type is set during create 
  # as a dynamic attribute for form simplicity, but once that happens serialization
  # invokes this getter and fails because framework is only set after the app has been
  # loaded from the server
  #def application_type
  #  ApplicationType.find(framework)
  #end

  protected
    def url_authority
      "#{name}-#{domain_id}#{RestApi.application_domain_suffix}"
    end
end
