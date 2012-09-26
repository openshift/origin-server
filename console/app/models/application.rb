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
    @gear_groups ||= GearGroup.simplify(GearGroup.find(:all, child_options), self)
  end

  def web_url
    app_url
  end

  #FIXME would prefer this come from REST API
  def ssh_url
    uri = URI.parse(git_url)
    uri.scheme = 'ssh'
    uri.path = ''
    uri.fragment = nil
    uri
  end

  # Helper to return the segment that would be provided for command line calls
  def ssh_string
    uri = ssh_url
    user = "#{uri.userinfo}@" if uri.userinfo
    port = ":#{uri.port}" if uri.port
    [user,uri.host,port].join
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

  def scale_status_url
    "#{web_url}haproxy-status/"
  end

  def build_job_url
    embedded.jenkins_build_url if embedded
  end
  def builds?
    build_job_url.present?
  end
  def jenkins_server?
    framework == 'jenkins-1.4'
  end

  # FIXME it is assumed that eventually this will be server functionality
  def destroy_build_cartridge
    cart = Cartridge.new({:application => self, :as => as, :name => 'jenkins-client-1.4'}, true)
    cart.destroy.tap{ |success| cart.errors.full_messages.each{ |m| errors.add(:base, m) } unless success }
  end

  def reload
    @gear_groups = nil
    super
  end

  protected
    def child_options
      { :params => { :domain_id => domain_id, :application_name => self.name},
        :as => as }
    end

end
