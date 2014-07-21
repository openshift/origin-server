#
# The REST API model object representing an application instance.
#
class Application < RestApi::Base
  include Membership

  class Member < ::Member
    belongs_to :application
    self.schema = ::Member.schema
  end

  schema do
    string :name, :creation_time
    string :id, :domain_id
    string :git_url, :app_url, :initial_git_url, :initial_git_branch
    string :server_identity
    string :gear_profile, :scale
    string :building_with, :build_job_url, :building_app
    string :framework
    string :region
    boolean :auto_deploy
    string :deployment_branch, :deployment_type, :keep_deployments
  end

  # Override to append the name to UI urls
  def to_param
    "#{id}-#{name}".parameterize if id.present?
  end

  # Override the instance method to use the ID-only when calling the REST API, instead of to_param
  def element_path(options = nil)
    self.class.element_path(id, options || prefix_options)
  end

  # Override the class method to not use the :domain_id prefix option when searching by id
  def self.element_path(id, prefix_options = {}, query_options = nil)
    if id
      prefix_options = prefix_options.dup.reject {|k| k == :domain_id } if prefix_options
      super
    elsif query_options and query_options[:name] and prefix_options and prefix_options[:domain_id]
      super(query_options.delete(:name), prefix_options, query_options)
    else
      super
    end
  end

  # Helper method to extract the ID from an ID param containing the name as well
  def self.id_from_param(param)
    param.to_s.gsub(/-.*/, '') if param
  end

  # Override to extract the real ID from the pretty ID before searching
  def self.find(*args)
    if args.first.is_a?(String)
      args[0] = id_from_param(args[0])
    end
    super(*args)
  end

  def self.suggest_name_from(cartridges)
    if cartridges.present?
      cartridges.each_pair do |k,v|
        if v.present?
          if c = v.find(&:web_framework?)
            return safe_name(c.suggest_name)
          elsif c = v.find(&:custom?)
            return safe_name(c.suggest_name)
          end
        end
      end
    end
    nil
  end

  def self.safe_name(name)
    name.downcase.gsub(/[^A-Za-z0-9]/,'')[0,32] if name
  end

  def valid?
    valid = super
    if id.blank? and domain_name.blank? and errors[:domain_name].blank?
      errors.add(:domain_name, 'Namespace is required')
      false
    else
      valid
    end
  end

  singular_resource

  belongs_to :domain
  alias_attribute :domain_name, :domain_id
  alias_attribute :scalable, :scale

  has_many :aliases
  has_many :cartridges
  has_many :gears
  has_many :gear_groups
  has_many :environment_variables
  has_one  :embedded, :class_name => as_indifferent_hash

  has_members :as => Application::Member

  attr_accessible :name, :scale, :gear_profile, :cartridges, :cartridge_names, :initial_git_url, :initial_git_branch, :region

  def find_cartridge(name)
    Cartridge.find name, child_options
  end

  def cartridges
    attributes[:cartridges] ||= persisted? ? Cartridge.find(:all, child_options) : []
  end

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
  attr_writer :gear_groups
  def cartridge_gear_groups
    @cartridge_gear_groups ||= GearGroup.infer(cartridges, self)
  end

  def environment_variables(skip_cache=false)
    attributes[:environment_variables] = begin
      if skip_cache or !attributes[:environment_variables]
        persisted? ? EnvironmentVariable.find(:all, child_options) : []
      else
        attributes[:environment_variables]
      end
    end
  end

  def restart!
    self.messages.clear
    response = post(:events, nil, {:event => :restart}.to_json)
    self.messages = extract_messages(response)
    true
  rescue ActiveResource::ClientError => error
    @remote_errors = error
    load_remote_errors(@remote_errors, true)
    false
  end

  def aliases(skip_cache=false)
    attributes[:aliases] = begin
      if skip_cache or !attributes[:aliases]
        persisted? ? Alias.find(:all, child_options) : []
      else
        attributes[:aliases]
      end
    end
  end
  def find_alias(id)
    Alias.find id, child_options
  end

  def remove_alias(alias_name)
    begin
      self.messages.clear
      response = post(:events, nil, {:event => 'remove-alias', :alias => alias_name}.to_json)
      self.messages = extract_messages(response)
      response.is_a? Net::HTTPOK
    rescue
      false
    end
  end

  def web_url
    app_url
  end

  def web_uri(scheme=nil)
    uri = URI.parse(app_url)
    uri.scheme = scheme
    uri
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

  def gear_ranges(account_max=Float::INFINITY)
    cartridge_gear_groups.inject({}) do |h, group|
      profile = (h[group.gear_profile] ||= [0, 0])
      count, max = 0, 0
      group.cartridges.each do |cart|
        count = [cart.current_scale, count].max
        max = [cart.will_scale_to(account_max), max].max
      end
      profile[0] += count
      profile[1] = [profile[1] + max, account_max].max
      h
    end.map{ |k, (v, v2)| [k, v, v2] }.sort_by{ |a| [a[1], a[2], a[0]] }.reverse
  end

  def scale_status_url
    URI.join(web_url, "/haproxy-status/").to_s
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
    [:@gear_groups, :@cartridge_gear_groups, :@framework_name].each{ |s| instance_variable_set(s, nil) }
    attributes.delete(:cartridges) if persisted?
    super
  end

  protected
    def child_prefix_options
      {:application_id => id}
    end

    def child_options
      { :params => child_prefix_options, :as => as }
    end

    def self.rescue_parent_missing(e, options=nil)
      parent = RestApi::ResourceNotFound.new(Domain.model_name, (options[:params][:domain_id] rescue nil), e.response)
      raise parent if parent.domain_missing?
    end
end
