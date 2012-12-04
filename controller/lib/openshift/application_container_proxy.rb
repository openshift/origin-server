module OpenShift
  class ApplicationContainerProxy
    @proxy_provider = OpenShift::ApplicationContainerProxy
    
    def self.valid_gear_sizes(user)
      @proxy_provider.valid_gear_sizes_impl(user)
    end
    
    def self.valid_gear_sizes_impl(user)    
      return ["small"]
    end

    def self.provider=(provider_class)
      @proxy_provider = provider_class
    end

    def self.instance(id)
      @proxy_provider.new(id)
    end

    def self.find_available(node_profile=nil)
      @proxy_provider.find_available_impl(node_profile)
    end

    def self.find_one(node_profile=nil)
      @proxy_provider.find_one_impl(node_profile)
    end

    def self.get_blacklisted
      @proxy_provider.get_blacklisted_in_impl
    end

    def self.get_blacklisted_in_impl
      []
    end


    def self.blacklisted?(name)
      @proxy_provider.blacklisted_in_impl?(name)
    end

    def self.blacklisted_in_impl?(name)
    end

    def self.get_all_gears
      @proxy_provider.get_all_gears_impl
    end

    def self.get_all_gears_impl
    end
    
    def self.get_all_active_gears
      @proxy_provider.get_all_active_gears_impl
    end

    def self.get_all_active_gears_impl
    end

    def self.execute_parallel_jobs(handle)
      @proxy_provider.execute_parallel_jobs_impl(handle)
    end

    def self.execute_parallel_jobs_impl(handle)
    end

    attr_accessor :id
    def self.find_available_impl(node_profile=nil)
    end

    def self.find_one_impl(node_profile=nil)
    end

    def reserve_uid
    end

    def unreserve_uid(uid)
    end

    def get_available_cartridges
    end

    def create(app, gear)
    end

    def destroy(app, gear)
    end

    def add_authorized_ssh_key(app, gear, ssh_key, key_type=nil, comment=nil)
    end

    def remove_authorized_ssh_key(app, gear, ssh_key, comment=nil)
    end

    def add_env_var(app, gear, key, value)
    end

    def remove_env_var(app, gear, key)
    end

    def add_broker_auth_key(app, gear, iv, token)
    end

    def remove_broker_auth_key(app, gear)
    end

    def show_state(app, gear)
    end

    def configure_cartridge(app, gear, cart, template_git_url=nil)
    end

    def deconfigure_cartridge(app, gear, cart)
    end

    def get_public_hostname
    end
    
    def get_quota_blocks
    end

    def get_quota_files
    end

    def execute_connector(app, gear, cart, connector_name, input_args)
    end

    def start(app, gear, cart)
    end

    def stop(app, gear, cart)
    end

    def force_stop(app, gear, cart)
    end

    def restart(app, gear, cart)
    end

    def reload(app, gear, cart)
    end

    def status(app, gear, cart)
    end

    def tidy(app, gear, cart)
    end

    def threaddump(app, gear, cart)
    end

    def system_messages(app, gear, cart)
    end

    def expose_port(app, gear, cart)
    end

    def conceal_port(app, gear, cart)
    end

    def show_port(app, gear, cart)
    end

    def add_alias(app, gear, server_alias)
    end

    def remove_alias(app, gear, server_alias)
    end

    def update_namespace(app, cart, new_ns, old_ns)
    end

    def get_quota(gear)
    end
    
    def set_quota(gear, storage_in_gb, inodes)
    end
    
    def framework_carts
    end

    def embedded_carts
    end

    def add_component(app, gear, component)
    end

    def remove_component(app, gear, component)
    end

    def start_component(app, gear, component)
    end

    def stop_component(app, gear, component)
    end

    def restart_component(app, gear, component)
    end

    def reload_component(app, gear, component)
    end

    def component_status(app, gear, component)
    end

    def has_app?(app_uuid, app_name)
    end

    def has_embedded_app?(app_uuid, embedded_type)
    end

    def get_env_var_add_job(app, gear, key, value)
    end
    
    def get_env_var_remove_job(app, gear, key)
    end

    def get_add_authorized_ssh_key_job(app, gear, ssh_key, key_type=nil, comment=nil)
    end
    
    def get_remove_authorized_ssh_key_job(app, gear, ssh_key, comment=nil)
    end
    
    def get_execute_connector_job(app, gear, cart, connector_name, input_args)
    end

    def get_broker_auth_key_add_job(app, gear, iv, token)
    end
  
    def get_broker_auth_key_remove_job(app, gear)
    end
    
    def get_show_state_job(app, gear)
    end

    def get_show_gear_quota_job(gear)
    end
    
    def get_update_gear_quota_job(gear, storage_in_gb, inodes)
    end
  end
end
