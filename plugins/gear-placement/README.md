The plugin architecture of the OpenShift broker allows us to introduce the
gear-placement plugin concept. When configured, the gear-placement plugin
will allow control of the placement of gears as they are created. The
algorithm can be implemented by a developer or operator with a basic
understanding of the Ruby programming language. We'll provide a few
examples here in the documentation of how you might go about creating
a custom algorithm based on some hypothetical scenarios.

Installation
------------

**Installation of the gear-placement plugin RPM on your OpenShift Broker host**

First, let's get started with the installation and configuration of the gear-placement plugin:

1) `sudo yum install rubygem-openshift-origin-gear-placement`

This will install a gem with a Rails engine containing the
GearPlacementPlugin class. The only method that you'll need to modify
is `self.select_best_fit_node_impl`, since this is the method
invoked by the `OpenShift::ApplicationContainerProxy` class. Whenever
a gear is created, the `ApplicationContainerProxy.select_best_fit_node`
method will be invoked and if there is a gear placement plugin installed,
that method will invoke the plugin.

**Configuration of the gear-placement plugin on your OpenShift Broker host**

2) `cp /etc/openshift/plugins.d/openshift-origin-gear-placement.conf{.example,}`

The installation step above not only installs the gear placement
plugin gem, it also lays down an example configuration file as
`/etc/openshift/plugins.d/openshift-origin-gear-placement.conf.example`.
Rename this file with the `.conf` extension; it serves as a marker file
for the broker to load the plugin. The broker automatically loads a gem
matching the file name, and the gem typically configures itself using
the file.

To see the default plugin in action now, `service openshift-broker restart`
and try to create an application. The default implementation does nothing
but log the plugin inputs and delegate to the standard algorithm, so
look in `/var/log/openshift/broker/production.log` to see it working.

Development
-----------

While developing a custom plugin, it will likely be helpful to set the
broker to development mode, which has several effects including:

1. Rails logs to development.log instead of production.log.
2. Rails logs at debug level instead of info.
3. The broker and plugins read configuration from files with the `-dev.conf` ending, if available.

To set the broker to development mode, do the following:

1. `touch /etc/openshift/development`
2. Copy `/etc/openshift/broker.conf` to broker-dev.conf, or just delete the latter to reuse prod settings
3. (optional) if you would like to use different plugin
settings in development mode, you can do so by copying
`/etc/openshift/plugins.d/openshift-origin-gear-placement.conf` to the
same file but ending with `-dev.conf` and editing that; this is only
read in development mode.
4. `service openshift-broker restart`

As you go through the development of your custom placement algorithm,
you may continue to alter the configuration file. Remember that after
altering this file or the gem, you should restart the `openshift-broker`
service in order to load the changes.

**Reading from the conf file with the initializer**

If you want to use configuration settings you need to add the settings to
`/etc/openshift/plugins.d/openshift-origin-gear-placement.conf` as well
as load them in the plugin initializer. You'll see in the stock
`config/initializers/openshift-origin-gear-placement.rb` the configuration
settings are loaded using the following:

     config.gear_placement = { :confkey1 => conf.get("CONFKEY1", "value1"),
                               :confkey2 => conf.get("CONFKEY2", "value2"),
                               :confkey3 => conf.get("CONFKEY3", "value3") }

Add your new configuration settings to the initializer using the same syntax as above.

**Implementation of the gear-placement algorithm**

The placement algorithm is specified as a method in
`lib/openshift/gear_placement_plugin.rb`. As the method signature suggests:

    GearPlacementPlugin.select_best_fit_node_impl(server_infos, app_props,
                       current_gears, comp_list, user_props, request_time)

...you have several data structures available for use in your algorithm.
In the end, the method must return exactly one of the entries from
`server_infos` (it cannot be a node outside the list).

The `server_infos` provided to the algorithm are already filtered for
compatibility with the gear request. Some of the filters are obvious,
while others may be surprising:

1. Specified profile
2. Specified region
3. Filter full/deactivated/undistricted nodes
4. Filter nodes without a region/zone, if regions/zones are in use
5. Filter zones already used in a HA app (depending on config)
6. Filter nodes already used in a scaled app, unless there would be no
nodes left (in which case only one is returned)
7. When a gear is being moved, filtered on availability of UID and other
constraints specified on the command

There are subtle nuances on some of these depending on circumstances.
Particularly in the last two cases, it would not be unusual for the
`server_infos` presented to the algorithm to only contain one node when
the developer might expect there to be plenty of other nodes to choose
from. The intent of the plugin (currently) is not to enable complete
flexibility of node choice, but rather to enforce custom constraints or
to load balance based on preferred parameters.

Let's go over the input data structures for convenience here:

* `server_infos`: Array of server information (array of objects of class `NodeProperties`)  -  `NodeProperties` - `:name, :node_consumed_capacity, :district_id, :district_available_capacity, :region_id, :zone_id`
* `app_props`: Properties of the application to which gear is being added (object of class `ApplicationProperties`)  - `ApplicationProperties - :id, :name, :web_cartridge`
* `current_gears`: Array of existing gears in the application (objects of class `GearProperties`)  - `GearProperties - :id, :name, :server, :district, :cartridges, :region, :zone`
* `comp_list`: Array of components that will be present on the new gear (objects of class `ComponentProperties`)  - `ComponentProperties - :cartridge_name, :component_name, :version, :cartridge_vendor`
* `user_props`: Properties of the user (object of class `UserProperties`)  - `UserProperties - :id, :login, :consumed_gears, :capabilities, :plan_id, :plan_state`
* `request_time`: the time that the request was sent to the plugin -  `Time.now` - Time on the OpenShift Broker host

The default plugin implementation just logs these values and delegates
to the standard placement algorithm, so check the logs after installation
for examples of these inputs.

Hypothetical Algorithms
-----------------------

The source for all algorithms below are available in this project
on GitHub and if you build and install the RPM, then the configuration files,
initializers, and algorithm source files will be installed. All
that is needed is to rename the file extensions to take the
place of the `/etc/openshift/openshift-origin-gear-placement.conf`,
`config/initializers/openshift/openshift-origin-gear-placement.rb`, and
`lib/openshift/gear_placement_plugin.rb` where they are installed on
your file system (the location of the gem will vary depending on version;
use `rpm -ql rubygem-openshift-origin-gear-placement` to find out where
these landed).

**Administrator Constraints**

*Just return the first node in the list*

    def self.select_best_fit_node_impl(server_infos, app_props, current_gears, comp_list, user_props, request_time)
      return server_infos.first
    end


*Place php applications on specific nodes*

(N.B. scaled/HA apps may interact with this surprisingly due to filters
noted above. A better way to achieve this would be to use the broker.conf
`VALID_GEAR_SIZES_FOR_CARTRIDGE` option in conjunction with profiles.)

    def self.select_best_fit_node_impl(server_infos, app_props, current_gears, comp_list, user_props, request_time)
      unless %w[php-5.3 php-5.4].include? app_props.web_cartridge 
        Rails.logger.debug("'#{app_props.web_cartridge}' is not a PHP app; selecting a node normally.")
        return OpenShift::MCollectiveApplicationContainerProxy.select_best_fit_node_impl(server_infos)
      end
      php_hosts = Broker::Application.config.gear_placement[:php_hosts]
      Rails.logger.debug("selecting a php node from: #{php_hosts.join ', '}")
      # figure out which of the nodes given is allowed for php carts
      matched_server_infos = server_infos.select {|x| php_hosts.include?(x.name) }
      matched_server_infos.empty? and
        raise "The gear-placement PHP_HOSTS setting doesn't match any of the NodeProfile names"
      return matched_server_infos.sample #chooses randomly from the matched hosts
    end


*Restrict a user's apps to slow hosts*

(N.B. this could prevent the user from scaling apps in some situations
due to filters noted above.)

    def self.select_best_fit_node_impl(server_infos, app_props, current_gears, comp_list, user_props, request_time) 
      config = Broker::Application.config.gear_placement  
      pinned_user = config[:pinned_user]           
      if pinned_user == user_props.login
        slow_hosts = config[:slow_hosts]
        Rails.logger.debug("user '#{pinned_user}' needs a gear; restrict to '#{slow_hosts.join ', '}'")
        matched_server_infos = server_infos.select {|x| slow_hosts.include?(x.name)}
        matched_server_infos.empty? and
          raise "The gear-placement SLOW_HOSTS setting does not match any available NodeProfile names"
        return matched_server_infos.first
      else
        Rails.logger.debug("user '#{user_props.login}' is not pinned; choose a node normally")
        return OpenShift::MCollectiveApplicationContainerProxy.select_best_fit_node_impl(server_infos)
      end
    end


*Blacklist a certain vendor's cartridges*

    def self.select_best_fit_node_impl(server_infos, app_props, current_gears, comp_list, user_props, request_time) 
      Rails.logger.debug("Using blacklist gear placement plugin to choose node.")
      Rails.logger.debug("selecting from nodes: #{server_infos.map(:name).join ', '}")
      blacklisted_vendor = Broker::Application.config.gear_placement[:blacklisted_vendor]
      unless blacklisted_vendor.nil?    
        comp_list.each do |comp|
          if blacklisted_vendor == comp.cartridge_vendor      
            raise "Applications containing cartridges from #{blacklisted_vendor} are blacklisted"
          end
        end
      end
      Rails.logger.debug("no contraband found, choosing node as usual")
      return OpenShift::MCollectiveApplicationContainerProxy.select_best_fit_node_impl(server_infos)
    end

**Resource Usage**

*Place gear on node with the most free memory*

    def self.select_best_fit_node_impl(server_infos, app_props, current_gears, comp_list, user_props, request_time) 
      # collect memory statistic from all nodes
      memhash = Hash.new(0)
      OpenShift::MCollectiveApplicationContainerProxy.rpc_get_fact('memoryfree') {|name,mem| memhash[name] = to_bytes(mem)}
      Rails.logger.debug("node memory hash: #{memhash.inspect}")
      # choose the one from our list with the largest value
      return server_infos.max_by {|server| memhash[server.name]} 
    end

    def self.to_bytes(mem)
      mem.to_f * case mem
        when /TB/; 1024 ** 4
        when /GB/; 1024 ** 3
        when /MB/; 1024 ** 2
        when /KB/; 1024
        else     ; 1
      end
    end

*Round Robin - Sort the nodes by gear usage*

The nodes in each profile will fill evenly (aside from complications due
to scaled apps, gears being deleted unevenly, mcollective fact updates
trailing reality, etc.).

Implementing true round robin would require writing out a state file owned
by this algorithm and using that for scheduling the placement rotation.

    def self.select_best_fit_node_impl(server_infos, app_props, current_gears, comp_list, user_props, request_time) 
      return server_infos.sort_by {|x| x.node_consumed_capacity.to_f}.first
    end

