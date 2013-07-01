module OpenShift
  class ApplicationContainerProxy
    @proxy_provider = OpenShift::ApplicationContainerProxy
    
    def self.valid_gear_sizes(user)
      @proxy_provider.valid_gear_sizes_impl(user)
    end
    
    def self.valid_gear_sizes_impl(user)    
      return Rails.configuration.openshift[:gear_sizes]
    end

    def self.provider=(provider_class)
      @proxy_provider = provider_class
    end

    def self.instance(id)
      @proxy_provider.new(id)
    end

    def self.find_available(node_profile=nil, district_uuid=nil, non_ha_server_identities=nil)
      @proxy_provider.find_available_impl(node_profile, district_uuid, non_ha_server_identities)
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
      false
    end

    def self.get_all_gears(opts = {})
      @proxy_provider.get_all_gears_impl(opts)
    end
    
    def self.get_all_active_gears
      @proxy_provider.get_all_active_gears_impl
    end

    def self.get_all_gears_sshkeys
      @proxy_provider.get_all_gears_sshkeys_impl
    end

    def self.execute_parallel_jobs(handle)
      @proxy_provider.execute_parallel_jobs_impl(handle)
    end

    attr_accessor :id
  end
end
