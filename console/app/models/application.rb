#
# The REST API model object representing an application instance.
#
class Application < RestApi::Base
  schema do
    string :name, :creation_time
    string :uuid, :domain_id
    string :git_url, :app_url, :initial_git_url, :initial_git_branch
    string :server_identity
    string :gear_profile, :scale
    string :building_with, :build_job_url, :building_app
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
  has_one  :embedded, :class_name => 'rest_api/base/attribute_hash'

  attr_accessible :name, :scale, :gear_profile, :cartridges, :cartridge_names, :initial_git_url, :initial_git_branch

  def find_cartridge(name)
    Cartridge.find name, child_options
  end

  def cartridges
    attributes[:cartridges] ||= persisted? ? Cartridge.find(:all, child_options) : []
  end
  #def cartridges=(arr)
  #  attributes[:cartridges] = Array(arr)
  #end

  def cartridge_names
    persisted? ? cartridges.map(&:name) : Array(attributes[:cartridges])
  end
  def cartridge_names=(arr)
    attributes[:cartridges] = Array(arr).map do |o|
      if String === o
        o
      elsif o.respond_to?(:[])
        o[:name]
      else
        o.name
      end
    end
  end

  def gears
    Gear.find :all, child_options
  end
  def gear_groups
    @gear_groups ||= GearGroup.find(:all, child_options)
  end
  def cartridge_gear_groups
    @cartridge_gear_groups ||= GearGroup.infer(cartridges, self)
  end

  def restart!
    post(:events, nil, {:event => :restart}.to_json)
    true
  end

  def aliases
    Alias.find :all, child_options
  end
  def find_alias(id)
    Alias.find id, child_options
  end
  def remove_alias(alias_name)
    begin
      response = post(:events, nil, {:event => 'remove-alias', :alias => alias_name}.to_json)
      response.is_a? Net::HTTPOK
    rescue
      false
    end
  end
  def remove_aliases
    self.aliases.each {|a| self.remove_alias(a.id) }
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

  def builds?
    building_with.present?
  end

  # FIXME it is assumed that eventually this will be server functionality
  def destroy_build_cartridge
    return true if !builds?
    cart = Cartridge.new({:application => self, :as => as, :name => building_with}, true)
    cart.destroy
  rescue ActiveResource::ConnectionError => e
    raise unless set_remote_errors(e, true)
    #end.tap{ |success| cart.errors.full_messages.each{ |m| errors.add(:base, m) } unless success }
  end

  def reload
    @gear_groups = nil
    @cartridge_gear_groups = nil
    super
  end

  protected
    def child_options
      { :params => { :domain_id => domain_id, :application_name => self.name},
        :as => as }
    end

    class << self
      def rescue_parent_missing(e, options=nil)
        parent = RestApi::ResourceNotFound.new(Domain.model_name, (options[:params][:domain_id] rescue nil), e.response)
        raise parent if parent.domain_missing?
      end
    end
end
