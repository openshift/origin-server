# Represents a gear created on an OpenShift Origin Node.
# @!attribute [r] group_instance
#   @return [GroupInstance] The {GroupInstance} that this gear is part of.
# @!attribute [r] server_identity
#   @return [String] DNS name of the node the gear is hosted on.
# @!attribute [r] uid
#   @return [Integer] UID of the user on the node.
# @!attribute [r] name
#   @return [String] name of the gear
#   @deprecated Will be removed once typeless gears is completed
class Gear
  include Mongoid::Document
  embedded_in :group_instance, class_name: GroupInstance.name
  field :server_identity, type: String
  field :uid, type: Integer
  field :name, type: String
  field :host_singletons, type: Boolean, default: false
  field :app_dns, type: Boolean, default: false

  # Initializes the gear
  def initialize(attrs = nil, options = nil)
    custom_id = attrs[:custom_id]
    attrs.delete(:custom_id)
    group_instance = attrs[:group_instance]
    attrs.delete(:group_instance)
    
    super(attrs, options)
    self._id = custom_id unless custom_id.nil?
    #@todo: Remove when typeless gears is completed
    if app_dns
      self.name = group_instance.application.name
    else
      self.name = self._id.to_s[0..9]
    end
  end
  
  def self.base_filesystem_gb(gear_size)
    CacheHelper.get_cached(gear_size + "_quota_blocks", :expires_in => 1.day) {
      proxy = OpenShift::ApplicationContainerProxy.find_one(gear_size)
      quota_blocks = Integer(proxy.get_quota_blocks)
      # calculate the minimum storage in GB - blocks are 1KB each
      quota_blocks / 1024 / 1024
    }
  end
  
  def reserve_uid
    @container = OpenShift::ApplicationContainerProxy.find_available(group_instance.gear_size)
    self.set :server_identity, @container.id
    self.set :uid, @container.reserve_uid
  end
  
  def unreserve_uid
    @container.unreserve_uid(self.uid)
    self.set :server_identity, nil
    self.set :uid, nil
  end
  
  def create_gear
    @container.create(app,self)
  end
  
  def destroy_gear
    @container.destroy(app,self)
  end
  
  def register_dns
    dns = OpenShift::DnsService.instance
    begin
      dns.register_application(self.name, self.group_instance.application.domain.namespace, public_hostname)
      dns.publish
    ensure
      dns.close
    end  
  end
  
  def deregister_dns
    dns = OpenShift::DnsService.instance
    begin
      dns.deregister_application(self.name, self.group_instance.application.domain.namespace)
      dns.publish
    ensure
      dns.close
    end
  end
  
  def status(component_instance)
    @container.status(app, self, component_instance.cartridge_name)
  end
  
  # Installs the specified component on the gear.
  #
  # == Parameters:
  # component::
  #   {ComponentInstance} to install.
  # == Returns:
  # A {ResultIO} object with with output or error messages from the Node.
  # Exit codes:
  #   success = 0
  # @raise [OpenShift::NodeException] on failure
  def add_component(component, init_git_url=nil)
    result_io = get_proxy.configure_cartridge(app, self, component.cartridge_name, init_git_url)
    component.process_properties(result_io)
    app.process_commands(result_io)
    raise OpenShift::NodeException.new("Unable to add component #{component.cartridge_name}::#{component.component_name}", result_io.exitcode, result_io) if result_io.exitcode != 0
    result_io
  end
  
  # Uninstalls the specified component from the gear.
  #
  # == Parameters:
  # component::
  #   {ComponentInstance} to uninstall.
  # == Returns:
  # A {ResultIO} object with with output or error messages from the Node.
  # Exit codes:
  #   success = 0
  # @raise [OpenShift::NodeException] on failure
  def remove_component(component)
    result_io = get_proxy.deconfigure_cartridge(app, self, component.cartridge_name)
    app.process_commands(result_io)
    result_io
  end
  
  # Used for identify methods like start/stop etc. which can be handled transparently by an {OpenShift::ApplicationContainerProxy}
  # @see Object::respond_to?
  # @see http://ruby-doc.org/core-1.9.3/Object.html#method-i-respond_to-3F
  def respond_to?(sym, include_private=false)
    get_proxy.respond_to?(sym, include_private) || super
  end
  
  # Used for handle methods like start/stop etc. which can be handled transparently by an {OpenShift::ApplicationContainerProxy}
  # @see BasicObject::method_missing
  # @see http://www.ruby-doc.org/core-1.9.3/BasicObject.html
  def method_missing(sym, *args, &block)
    sym = :reload if sym == :reload_config
    new_args = args.dup.unshift(app, self)
    return get_proxy.send(sym, *new_args) if get_proxy.respond_to?(sym, false)
    super(sym, *args, &block)
  end
  
  # Gets the public hostname for the Node this gear is hosted on
  # == Returns:
  # @return [String] Public hostname of the node the gear is hosted on.
  def public_hostname
    get_proxy.get_public_hostname
  end
  
  # Given a set of gears, retrueve the state of the gear
  #
  # == Parameters:
  # gears::
  #   Array of {Gear}s to retrieve state for.
  #
  # == Returns:
  # Hash of Gear._id => state representing the state of each gear
  def self.get_gear_states(gears)
    gear_states = {}
    tag = ""
    handle = RemoteJob.create_parallel_job
    RemoteJob.run_parallel_on_gears(gears, handle) { |exec_handle, gear|
      RemoteJob.add_parallel_job(exec_handle, tag, gear, gear.get_proxy.get_show_state_job(gear.app, gear))
    }
    RemoteJob.get_parallel_run_results(handle) { |tag, gear, output, status|
      if status != 0
        Rails.logger.error("Error getting application state from gear: '#{gear}' with status: '#{status}' and output: #{output}", 143)
        gear_states[gear] = 'unknown'
      else
        gear_states[gear] = output
      end
    }
    gear_states
  end

  # Retrieves the instance of {OpenShift::ApplicationContainerProxy} that backs this gear
  #
  # == Returns:
  # {OpenShift::ApplicationContainerProxy}
  def get_proxy
    if @container.nil? and !self.server_identity.nil?
      @container = OpenShift::ApplicationContainerProxy.instance(self.server_identity)
    end    
    return @container
  end

  def update_configuration(args, remote_job_handle)
    add_keys = args["add_keys_attrs"]
    remove_keys = args["remove_keys_attrs"]
    add_envs = args["add_env_vars"]
    remove_envs = args["remove_env_vars"]
    tag = ""
    
    add_keys.each     { |ssh_key| RemoteJob.add_parallel_job(remote_job_handle, tag, self, self.get_add_authorized_ssh_key_job(ssh_key["content"], ssh_key["type"], ssh_key["name"])) } unless add_keys.nil?      
    remove_keys.each  { |ssh_key| RemoteJob.add_parallel_job(remote_job_handle, tag, self, self.get_remove_authorized_ssh_key_job(ssh_key["content"], ssh_key["name"])) } unless remove_keys.nil?                 
                                                                                           
    add_envs.each     {|env|      RemoteJob.add_parallel_job(remote_job_handle, tag, self, self.env_var_job_add(env["key"],env["value"]))} unless add_envs.nil?                                                   
    remove_envs.each  {|env|      RemoteJob.add_parallel_job(remote_job_handle, tag, self, self.env_var_job_remove(env["key"]))} unless remove_envs.nil?
  end

  # Convenience method to get the {Application}
  def app
    @app ||= group_instance.application
  end
  
  def set_addtl_fs_gb(filesystem_gb, remote_job_handle)
    return if self.group_instance.addtl_fs_gb == filesystem_gb
    RemoteJob.add_parallel_job(remote_job_handle, "addtl-fs-gb", self, get_proxy.get_update_gear_quota_job(self, filesystem_gb,""))
  end

  def update_namespace(args, handle)
    old_ns = args["old_namespace"]
    new_ns = args["new_namespace"]
    cart = args["cartridge"]

    dns = OpenShift::DnsService.instance
    begin
      dns.deregister_application(self.name, old_ns, public_hostname)
      dns.register_application(self.name, new_ns, public_hostname)
      dns.publish
    ensure
      dns.close
    end  

    result = ResultIO.new
    result.append get_proxy.update_namespace(self.app, self, cart, new_ns, old_ns)
    self.app.process_commands(result)
  end
end
