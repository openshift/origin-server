class Gear < OpenShift::Model
  attr_accessor :uuid, :uid, :server_identity, :group_instance_name, :node_profile, :container, :app, :configured_components, :name
  primary_key :uuid
  exclude_attributes :container, :app
  
  def initialize(app, group_instance, uuid=nil, uid=nil)
    self.app = app
    @uuid = uuid || OpenShift::Model.gen_uuid
    self.name = @uuid[0..9]
    self.group_instance_name = group_instance.name
    self.node_profile = group_instance.node_profile
    self.configured_components = []
    @uid = uid
    get_proxy
  end
  
  def node_profile
    # node_profile can be nil for older data.  Should migrate everything to have a node_profile 
    # with the next major migration.  Although technically node_profile shouldn't even be on gear.
    if @node_profile.nil?
      return Application::DEFAULT_NODE_PROFILE
    else
      return @node_profile
    end
  end
  
  def get_proxy
    if self.container.nil? and !@server_identity.nil?
      self.container = OpenShift::ApplicationContainerProxy.instance(@server_identity)
    end    
    return self.container
  end
  
  def create
    if server_identity.nil?
      ret = nil
      begin
        self.app.ngears += 1
        self.container = OpenShift::ApplicationContainerProxy.find_available(self.node_profile)
        self.server_identity = self.container.id
        self.uid = self.container.reserve_uid
        self.group_instance.gears << self
        self.app.save
        ret = self.container.create(app,self)
        self.app.track_usage(self, UsageRecord::EVENTS[:begin]) if ret.exitcode == 0
      rescue Exception => e
        Rails.logger.debug e.message
        Rails.logger.debug e.backtrace.join("\n")
        ret = ResultIO.new
        ret.errorIO << e.message
        ret.exitcode = 5
      end

      ## recovery action if creation failed above
      if ret.exitcode != 0
        begin
          get_proxy.destroy(self.app, self)
        rescue Exception => e
        end
        self.app.ngears -= 1
        self.group_instance.gears.delete(self)
        self.app.save
        raise OpenShift::NodeException.new("Unable to create gear on node", 1, ret)
      end
      return ret
    end
  end

  def destroy
    ret = get_proxy.destroy(app, self)
    if ret.exitcode == 0
      self.app.destroyed_gears = [] unless self.app.destroyed_gears
      self.app.destroyed_gears << @uuid
      track_destroy_usage
      self.app.ngears -= 1
      self.group_instance.gears.delete(self)
      app.process_cartridge_commands(ret)
      self.app.save
    else
      raise OpenShift::NodeException.new("Unable to destroy gear on node", 1, ret)
    end
    return ret
  end

  def force_destroy
    ret = nil
    begin
      begin
        ret = get_proxy.destroy(app, self)
      rescue Exception => e
        Rails.logger.error("ERROR: Ignoring a failed destroy for gear with uuid: #{uuid}")
      end
      self.app.destroyed_gears = [] unless self.app.destroyed_gears
      self.app.destroyed_gears << @uuid
      track_destroy_usage
    ensure
      self.app.ngears -= 1
      self.group_instance.gears.delete(self)
      if ret
        begin
          app.process_cartridge_commands(ret)
        rescue Exception => e
          Rails.logger.error("ERROR: Ignoring a failed process_cartridge_commands for gear with uuid: #{uuid}")
        end
      end
      self.app.save
    end
    return ret
  end
  
  def configure(comp_inst, template_git_url=nil)
    r = ResultIO.new
    return r if self.configured_components.include?(comp_inst.name)
    result_io, cart_data = get_proxy.configure_cartridge(app, self, comp_inst.parent_cart_name, template_git_url)
    r.append result_io
    comp_inst.process_cart_data(cart_data)
    comp_inst.process_cart_properties(result_io.cart_properties)
    self.configured_components.push(comp_inst.name)
    r
  end
  
  def deconfigure(comp_inst, force=false)
    r = ResultIO.new
    return r unless self.configured_components.include?(comp_inst.name) or force
    r.append get_proxy.deconfigure_cartridge(app,self,comp_inst.parent_cart_name)
    self.configured_components.delete(comp_inst.name)
    r
  end

  def execute_connector(comp_inst, connector_name, input_args)
    get_proxy.execute_connector(app, self, comp_inst.parent_cart_name, connector_name, input_args)
  end
  
  def get_execute_connector_job(cart, connector_name, input_args)
    get_proxy.get_execute_connector_job(app, self, cart, connector_name, input_args)
  end

  def start(comp_inst)
    get_proxy.start(app, self, comp_inst.parent_cart_name)
  end
  
  def stop(comp_inst)
    get_proxy.stop(app, self, comp_inst.parent_cart_name) 
  end
  
  def restart(comp_inst)
    get_proxy.restart(app, self, comp_inst.parent_cart_name)
  end
  
  def force_stop(comp_inst)
    get_proxy.force_stop(app, self, comp_inst.parent_cart_name)
  end
  
  def reload(comp_inst)
    get_proxy.reload(app, self, comp_inst.parent_cart_name)
  end
  
  def status(comp_inst)
    get_proxy.status(app, self, comp_inst.parent_cart_name)
  end

  def status_job(comp_inst)
    job = get_proxy.get_status_job(app, self, comp_inst.parent_cart_name)
    job
  end
  
  def show_state()
    get_proxy.show_state(app, self)
  end

  def tidy(comp_inst)
    get_proxy.tidy(app, self, comp_inst.parent_cart_name)
  end

  def expose_port(comp_inst)
    get_proxy.expose_port(app, self, comp_inst.parent_cart_name)
  end

  def conceal_port(comp_inst)
    get_proxy.conceal_port(app, self, comp_inst.parent_cart_name)
  end
 
  def show_port(comp_inst)
    get_proxy.show_port(app, self, comp_inst.parent_cart_name)
  end
 
  def threaddump(comp_inst)
    get_proxy.threaddump(app, self, comp_inst.parent_cart_name)
  end
  
  def system_messages(comp_inst)
    get_proxy.system_messages(app, self, comp_inst.parent_cart_name)
  end
  
  def add_alias(server_alias)
    if app.gear.uuid == self.uuid
      get_proxy.add_alias(app, self, server_alias)
    else
      ResultIO.new
    end
  end
  
  def remove_alias(server_alias)
    if app.gear.uuid == self.uuid
      get_proxy.remove_alias(app, self, server_alias)
    else
      ResultIO.new
    end
  end
    
  def add_authorized_ssh_key(ssh_key, key_type=nil, comment=nil)
    get_proxy.add_authorized_ssh_key(app, self, ssh_key, key_type, comment)
  end
  
  def remove_authorized_ssh_key(ssh_key, comment=nil)
    get_proxy.remove_authorized_ssh_key(app, self, ssh_key, comment)
  end
  
  def add_env_var(key, value)
    get_proxy.add_env_var(app, self, key, value)
  end
  
  def set_quota(storage_in_gb, inodes)
    get_proxy.set_quota(self, storage_in_gb, inodes)
  end
  
  def get_quota()
    get_proxy.get_quota(self)
  end
  
  def gear_quota_job_show()
    job = get_proxy.get_show_gear_quota_job(self)
    job
  end
  
  def gear_quota_job_update(storage_in_gb, inodes)
    job = get_proxy.get_update_gear_quota_job(self, storage_in_gb, inodes)
    job
  end
  
  def app_state_job_show()
    job = get_proxy.get_show_state_job(app, self)
    job
  end
 
  def env_var_job_add(key, value)
    job = get_proxy.get_env_var_add_job(app, self, key, value)
    job
  end
  
  def ssh_key_job_add(ssh_key, ssh_key_type, ssh_key_comment)
    job = get_proxy.get_add_authorized_ssh_key_job(app, self, ssh_key, ssh_key_type, ssh_key_comment)
    job
  end
  
  def broker_auth_key_job_add(iv, token)
    job = get_proxy.get_broker_auth_key_add_job(app, self, iv, token)
    job
  end
  
  def env_var_job_remove(key)
    job = get_proxy.get_env_var_remove_job(app, self, key)
    job
  end
  
  def ssh_key_job_remove(ssh_key, ssh_key_comment)
    job = get_proxy.get_remove_authorized_ssh_key_job(app, self, ssh_key, ssh_key_comment)
    job
  end
  
  def broker_auth_key_job_remove()
    job = get_proxy.get_broker_auth_key_remove_job(app, self)
    job
  end
  
  def remove_env_var(key)
    get_proxy.remove_env_var(app, self, key)
  end
  
  def add_broker_auth_key(iv,token)
    get_proxy.add_broker_auth_key(app, self, iv, token)
  end
  
  def remove_broker_auth_key
    get_proxy.remove_broker_auth_key(app, self)    
  end
  
  def cartridges
    gi = group_instance
    carts = gi.component_instances.map{ |comp_instance_name| app.comp_instance_map[comp_instance_name].parent_cart_name }
    carts.delete(app.name)
    carts
  end
  
  def group_instance
    self.app.group_instance_map[self.group_instance_name]
  end
  
  def group_instance_name
    return @group_instance_name if self.app.group_instance_map[@group_instance_name]
    self.app.group_instance_map.each { |gi_name, gi|
      gi.gears.each { |gi_gear|
        if gi_gear.uuid==self.uuid
          @group_instance_name = gi_name
          return @group_instance_name
        end
      }
    }
    return self.app.get_name_prefix
  end

  def prepare_namespace_update(dns_service, new_ns, old_ns)
    results = []
    gi = group_instance
    contains_proxy = false
    contains_framework = false
    result_io = ResultIO.new
    
    gi.component_instances.each do |cname|
      ci = self.app.comp_instance_map[cname]
      contains_proxy = true if ci.parent_cart_name == self.app.proxy_cartridge
      contains_framework = true if ci.parent_cart_name == self.app.framework    
    end

    if contains_proxy || !self.app.scalable
      #proxy gear gets public dns
      register_application(dns_service, old_ns, new_ns, self.app.name)
    else
      #non-proxy gear gets gear specific dns
      register_application(dns_service, old_ns, new_ns, self.name)
    end

    if contains_framework
      result_io.append call_update_namespace_hook(self.app.framework, new_ns, old_ns)
    else
      result_io.append call_update_namespace_hook("abstract", new_ns, old_ns)
    end
    result_io
  end
  
  def self.valid_gear_size?(gear_size)
    Rails.configuration.openshift[:gear_sizes].include?(gear_size)
  end
  
  def self.gear_sizes_display_string
    # Ex: (small(default)|jumbo|exlarge|large|medium|micro)
    out = '('
    Rails.configuration.openshift[:gear_sizes].each_with_index do |gear_size, index|
      out += gear_size
      out += '(default)' if gear_size == Rails.configuration.openshift[:default_gear_size] 
      out += '|' unless index == (Rails.configuration.openshift[:gear_sizes].length - 1) 
    end
    out += ')'
  end

private

  def track_destroy_usage
    self.app.track_usage(self, UsageRecord::EVENTS[:end])
    if self.group_instance.addtl_fs_gb && self.group_instance.addtl_fs_gb > 0
      self.app.track_usage(self, UsageRecord::EVENTS[:end], UsageRecord::USAGE_TYPES[:addtl_fs_gb])
    end
  end

  def call_update_namespace_hook(cart_name, new_ns, old_ns)
    result = get_proxy.update_namespace(self.app, self, cart_name, new_ns, old_ns)
    self.app.process_cartridge_commands(result)
    return result
  end

  def register_application(dns_service, old_ns, new_ns, name)
    public_hostname = get_proxy.get_public_hostname
    dns_service.deregister_application(name, old_ns)
    dns_service.register_application(name, new_ns, public_hostname)
  end
end
