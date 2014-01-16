module OpenShift
  class ApplicationContainerProxy
    @proxy_provider = OpenShift::ApplicationContainerProxy
    @node_selector = nil

    def self.valid_gear_sizes
      @proxy_provider.valid_gear_sizes_impl
    end

    def self.valid_gear_sizes_impl
      return Rails.configuration.openshift[:gear_sizes]
    end

    def self.provider=(provider_class)
      @proxy_provider = provider_class
    end

    def self.node_selector_plugin=(node_selector_plugin_class)
      @node_selector = node_selector_plugin_class
    end

    def self.instance(id)
      @proxy_provider.new(id)
    end

    def self.find_available(node_profile=nil, district_uuid=nil, non_ha_server_identities=nil, gear=nil)
      server_infos = @proxy_provider.find_all_available_impl(node_profile, district_uuid, non_ha_server_identities)
      server_id, district = select_best_fit_node(server_infos, gear)
      
      raise OpenShift::NodeUnavailableException.new("No nodes available", 140) if server_id.nil?
      @proxy_provider.new(server_id, district)
    end

    def self.find_one(node_profile=nil)
      server_id = @proxy_provider.find_one_impl(node_profile)
      raise OpenShift::NodeUnavailableException.new("No nodes available", 140) if server_id.blank?
      @proxy_provider.new(server_id)
    end

    def self.select_best_fit_node(server_infos, gear)
      server_id = nil
      district = nil
      if @node_selector.nil?
        server_info = @proxy_provider.select_best_fit_node_impl(server_infos)
        server_id = server_info[0]
        district = server_info[2]
      else
        node_list = server_infos.map {|server| NodeProperties.new(server[0], server[1], server[2])}
        
        if gear
          app_props = ApplicationProperties.new(gear.application)
          user_props = UserProperties.new(gear.application.domain.owner)
          current_gears = gear.application.gears.map {|g| GearProperties.new(g) unless g.server_identity.nil?}
          current_gears.delete_if {|g| g.nil?}
          comp_list = gear.component_instances.map {|ci| ComponentProperties.new(ci)}
        end

        # sending the request time to the plugin
        # since the request is processed inline currently, sending Time.now for now
        # later, if asynchronous request processing is performed, we will store the request time and pass it along 
        request_time = Time.now
        node = @node_selector.select_best_fit_node_impl(node_list, app_props, current_gears, comp_list, user_props, request_time)
        server_id = node.name
        district = District.find_by(:_id => node.district_id) if node.district_id
      end

      return server_id, district
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

    def self.get_all_gears_endpoints(opts = {})
      @proxy_provider.get_all_gears_endpoints_impl(opts)
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

    def self.get_details_for_all(name_list)
      @proxy_provider.get_details_for_all_impl(name_list)
    end

    def self.set_district_uid_limits(uuid, first_uid, max_uid)
      @proxy_provider.set_district_uid_limits_impl(uuid, first_uid, max_uid) 
    end

    attr_accessor :id
  end
end
