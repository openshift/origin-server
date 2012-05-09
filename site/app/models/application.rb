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

  belongs_to :domain
  alias_attribute :domain_name, :domain_id

  has_many :aliases
  has_many :cartridges
  has_many :gears
  has_many :gear_groups

  def find_cartridge(name)
    Cartridge.find name, child_options
  end

  def cartridges
    Cartridge.find :all, child_options
  end
  def gears
    Gear.find :all, child_options
  end
  def gear_groups
    GearGroup.find :all, child_options
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

  protected
    def url_authority
      "#{name}-#{domain_id}.#{Rails.configuration.base_domain}"
    end
    def child_options
      { :params => { :domain_id => domain_id, :application_name => self.name},
        :as => as }
    end

end
