#
# The REST API model object representing an application instance.
#
class Application < RestApi::Base
  schema do
    string :name, :creation_time
    string :uuid, :domain_id
    string :git_url, :app_url
    string :server_identity
    string :gear_profile, :scale
  end

  custom_id :name
  def id #FIXME provided as legacy support for accessing .name via .id
    name
  end

  belongs_to :domain
  alias_attribute :domain_name, :domain_id
  alias_attribute :scalable, :scale

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
    GearGroup.simplify(GearGroup.find(:all, child_options), self)
  end

  def web_url
    app_url
  end

  def framework_name
    @framework_name ||= CartridgeType.cached.find(framework, :as => as).display_name rescue framework
  end

  def embedded
    @attributes[:embedded]
  end

  def scales?
    scale
  end

  def build_job_url
    embedded.jenkins_build_url if embedded
  end
  def builds?
    build_job_url.present?
  end

  protected
    def child_options
      { :params => { :domain_id => domain_id, :application_name => self.name},
        :as => as }
    end

end
