class Gear < StickShift::UserModel
  attr_accessor :uuid, :uid, :server_identity, :group_instance_name, :node_profile, :container, :app, :configured_components, :name
  primary_key :uuid
  exclude_attributes :container, :app
  
  def initialize(app, group_instance, uuid=nil, uid=nil)
    self.app = app
    @uuid = uuid || StickShift::Model.gen_uuid
    self.name = @uuid[0..9]
    self.group_instance_name = group_instance.name
    self.node_profile = group_instance.node_profile
    self.configured_components = []
    get_proxy
  end
  
  def get_proxy
    if self.container.nil? and !@server_identity.nil?
      self.container = StickShift::ApplicationContainerProxy.instance(@server_identity)
    end    
    return self.container
  end
  
  def create
    if server_identity.nil?
      self.container = StickShift::ApplicationContainerProxy.find_available(self.node_profile)
      self.server_identity = self.container.id
      self.uid = self.container.reserve_uid
      ret = self.container.create(app,self)
      self.app.ngears += 1
      return ret
    end
  end

  def destroy
    self.app.ngears -= 1
    ret = get_proxy.destroy(app,self)
    return ret
  end
  
  def expose_port(comp_inst)
    get_proxy.expose_port(app,self,comp_inst.parent_cart_name)
  end

  def conceal_port(comp_inst)
    get_proxy.conceal_port(app,self,comp_inst.parent_cart_name)
  end
  
  def show_port(comp_inst)
    get_proxy.show_port(app,self,comp_inst.parent_cart_name)
  end
  
  def configure(comp_inst, template_git_url=nil)
    r = ResultIO.new
    return r if self.configured_components.include?(comp_inst.name)
    r.append get_proxy.preconfigure_cartridge(app,self,comp_inst.parent_cart_name)
    result_io,cart_data = get_proxy.configure_cartridge(app,self,comp_inst.parent_cart_name, template_git_url)
    r.append result_io
    comp_inst.process_cart_data(cart_data)
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
    get_proxy.start(app,self,comp_inst.parent_cart_name)
  end
  
  def stop(comp_inst)
    get_proxy.stop(app,self,comp_inst.parent_cart_name)    
  end
  
  def restart(comp_inst)
    get_proxy.restart(app,self,comp_inst.parent_cart_name)    
  end
  
  def force_stop(comp_inst)
    get_proxy.force_stop(app,self,comp_inst.parent_cart_name)    
  end
  
  def reload(comp_inst)
    get_proxy.reload(app,self,comp_inst.parent_cart_name)    
  end
  
  def status(comp_inst)
    get_proxy.status(app,self,comp_inst.parent_cart_name)    
  end
  
  def tidy(comp_inst)
    get_proxy.tidy(app,self,comp_inst.parent_cart_name)    
  end

  def expose_port(comp_inst)
    get_proxy.expose_port(app,self,comp_inst.parent_cart_name)
  end

  def conceal_port(comp_inst)
    get_proxy.conceal_port(app,self,comp_inst.parent_cart_name)
  end
 
  def show_port(comp_inst)
    get_proxy.show_port(app,self,comp_inst.parent_cart_name)
  end
 
  def threaddump(comp_inst)
    get_proxy.threaddump(app,self,comp_inst.parent_cart_name)    
  end
  
  def system_messages(comp_inst)
    get_proxy.system_messages(app,self,comp_inst.parent_cart_name)    
  end
  
  def add_alias(server_alias)
  end
  
  def remove_alias(server_alias)
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
end
