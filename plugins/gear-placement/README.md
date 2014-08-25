The plugin architecture of OpenShift allows us to introduce the gear-placement plugin concept. When configured, the gear-placement plugin will allow an operator to control the placement of gears as they are created. The algorithm can be implemented by a developer or operator with some pretty basic understanding of the Ruby programming language. We'll provide a few examples here in the documentation of how you might go about creating a custom algorithm based on some hypothetical scenarios.

Installation
------------

**Installation of the gear-placement plugin on your OpenShift Broker host**

First, let's get started with the installation and configuration of the gear-placement plugin:
1. sudo yum install rubygem-openshift-origin-gear-placement
    This will install the Rails engin that will load the GearPlacementPlugin class. The only method that you'll need to modify is the self.select_best_fit_node_impl, since this is the method that's invoked by the OpenShift::ApplicationContainerProxy class. Whenever a gear is created, the ApplicationContainerProxy.select_best_fit_node method will be invoked and if there is a gear placement plugin installed, that method will invoke the plugin.
    Restart the openshift-broker service (unless you are going to alter the gear placement plugin configuration file, then you can wait to restart the service until after you're done modifying the configuration file)

**Configuration of the gear-placement plugin on your OpenShift Broker host**

2. The installation step above not only installs the gear placement plugin, it also lays down an example configuration file as /etc/openshift/plugins.d/openshift-origin-gear-placement.conf.example. This file will only get loaded if it is renamed with a .conf extension or if using the development environment, the file can end with -dev.conf. In the absense of -dev.conf, the .conf file will be used.

As you go through the development of your custom placement algorithm, you may continue to alter the configuration file. Rember that after altering this file, you should restart the openshift-broker service. If you're not configuring the the gear placement plugin with the config file, you can ignore the file and not even change the extension. We'll go through examples of both.

If you want to add configuration settings you need add the settings to /etc/openshift/plugins.d/openshift-origin-gear-placement.conf as well as load the settings in the plugin initializer. You'll see in the stock config/initializers/openshift-origin-gear-placement.rb the configuration settings are loaded using the following:

     config.gear_placement = { :confkey1 => conf.get("GEAR_PLACEMENT_CONFKEY1", "value1"),
                               :confkey2 => conf.get("GEAR_PLACEMENT_CONFKEY2", "value2"),
                               :confkey3 => conf.get("GEAR_PLACEMENT_CONFKEY3", "value3") }

Add your new configuration settings to the initializer using the same syntax as above.

**Customization of the gear-placement algorithm**

As the method signature of
    GearPlacementPlugin.select_best_fit_node_impl(server_infos, app_props, current_gears, comp_list, user_props, request_time)

suggests, you have several data structures you can evaluate in your algorith (you can also ignore them and do whatever else you want with the algorithm, but at the end of your algorithm, you must return exactly one service_info (NodeProperties)

Let's go over the input data structures for convenience here:

* server_infos: Array of server information (array of objects of class NodeProperties)  -  NodeProperties - :name, :node_consumed_capacity, :district_id, :district_available_capacity, :region_id, :zone_id

* app_props: Properties of the application to which gear is being added (object of class ApplicationProperties)  - Application Properties - :id, :name, :web_cartridge

* current_gears: Array of existing gears in the application (objects of class GearProperties)  - GearProperties - :id, :name, :server, :district, :cartridges, :region, :zone

* comp_list: Array of components that will be present on the new gear (objects of class ComponentProperties)  - ComponentProperties - :cartridge_name, :component_name, :version, :cartridge_vendor

* user_props: Properties of the user (object of class UserProperties)  - UserProperties - :id, :login, :consumed_gears, :capabilities, :plan_id, :plan_state

* request_time: the time that the request was sent to the plugin -  Time.now - Time on the OpenShift Broker host

Hypothetical Algorithms
-----------------------

The source for all algorithms below are available in this project on GitHub and if you build the rpm, the configuration files, initializers, and algorithm source files will be installed. All that is needed is to rename the file extensions to take the place of the /etc/openshift/openshift-origin-gear-placement.conf, config/initializers/openshift/openshift-origin-gear-placement.rb, and lib/openshift/gear_placement_plugin.rb.

**Administrator Controlled**

Return the first node in the list

    def self.select_best_fit_node_impl(server_infos, app_props, current_gears, comp_list, user_props, request_time)
      return server_infos.first
    end


*Place php applications on specific node*

    def self.select_best_fit_node_impl(server_infos, app_props, current_gears, comp_list, user_props, request_time)
      config = Broker::Application.config.gear_placement
      php_host = config[:PHP_HOST]
      if php_host.nil?
        raise "The gear-placemement plugin expects a configuration setting for :PHP_HOST and it's missing"
      end
      check_server_infos = server_infos
      check_server_infos.select {|x| x.name.eql? php_host}
      if check_server_infos.empty?
        raise "The gear-placement configuration has a :PHP_HOST setting that doesn't match any of the NodeProfile names"
      end
      server_infos.each do |server_info|
        if (server_info.name.eql? php_host) && ("php".eql? app_props.web_cartridge)
          return server_info
        end
      end
      return server_infos.first
    end

*Place gshipley's apps on a really slow host*

    def self.select_best_fit_node_impl(server_infos, app_props, current_gears, comp_list, user_props, request_time)
      config = Broker::Application.config.gear_placement
      slow_host = config[:SLOW_HOST]
      pinned_user = config[:PINNED_USER]
      if slow_host.nil?
        raise "The gear-placemement plugin expects a configuration setting for :SLOW_HOST and it's missing"
      end
      if pinned_user.nil?
        raise "The gear-placement lugin expects a configuration setting for :PINNED_USER and it's missing"
      end
      check_server_infos = server_infos
      check_server_infos.select {|x| x.name.eql? slow_host}
      if check_server_infos.empty?
        raise "The gear-placement configuration has a :SLOW_HOST setting that doesn't match any of the NodeProfile names"
      end
      server_infos.each do |server_info|
        if (server_info.name.eql? slow_host) && (pinned_user.eql? user_props.login)
          return server_info
        end
      end
      return server_infos.first
    end

*Blacklist any applications built on a certain vendor's cartridges, else just return the first server_info*

    def self.select_best_fit_node_impl(server_infos, app_props, current_gears, comp_list, user_props, request_time)
      config = Broker::Application.config.gear_placement
      blacklisted_vendor = config[:BLACKLISTED_VENDOR]
      if (!blacklisted_vendor.nil?)
        comp_list.each do |comp|
          if (blacklisted_vendor.eql? comp.cartridge_vendor)
            raise "Applications containing cartridges from #{comp.cartridge_vendor} are blacklisted"
          end
        end
      end
      return server_infos.first
    end

**Round Robin**

*Sort the nodes by hostname, as long as this algorithm has been used from the begining, the first server_info after the sort will be the next one to select. The alternative is to write out a state file, owned by this algorithm and use that as the reference*.

    def self.select_best_fit_node_impl(server_infos, app_props, current_gears, comp_list, user_props, request_time)
      server_infos.sort_by {|x| x.node_consumed_capacity}
      return server_infos.first
    end

**Resource Usage**

*Place gear on node with the most free memory*

    def self.select_best_fit_node_impl(server_infos, app_props, current_gears, comp_list, user_props, request_time)
      nodes = Hash.new
      OpenShift::MCollectiveApplicationContainerProxy.rpc_get_fact('memoryfree')  do |x, profile|
         nodes[x] = profile
      end
      node_profiles = nodes.sort_by {|k, v| v}
      server_info = server_infos.select {|v| v.name.eql? node_profiles.last.first}
      return server_info.first
    end


