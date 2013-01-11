require 'mcollective'
require 'open-uri'

include MCollective::RPC
module OpenShift
    class MCollectiveApplicationContainerProxy < OpenShift::ApplicationContainerProxy
      @@C_CONTROLLER = 'openshift-origin-node'
      attr_accessor :id, :district
      
      def initialize(id, district=nil)
        @id = id
        @district = district
      end
      
      def self.valid_gear_sizes_impl(user)
        capability_gear_sizes = []
        capability_gear_sizes = user.capabilities['gear_sizes'] if user.capabilities.has_key?('gear_sizes')

        if user.auth_method == :broker_auth
          return ["small", "medium"] | capability_gear_sizes
        elsif !capability_gear_sizes.nil? and !capability_gear_sizes.empty?
          return capability_gear_sizes
        else
          return ["small"]
        end
      end
      
      def self.find_available_impl(node_profile=nil, district_uuid=nil)
        district = nil
        require_specific_district = !district_uuid.nil?
        if Rails.configuration.msg_broker[:districts][:enabled] && (!district_uuid || district_uuid == 'NONE')
          district = District.find_available(node_profile)
          if district
            district_uuid = district.uuid
            Rails.logger.debug "DEBUG: find_available_impl: district_uuid: #{district_uuid}"
          elsif Rails.configuration.msg_broker[:districts][:require_for_app_create]
            raise OpenShift::NodeException.new("No district nodes available.", 140)
          end
        end
        current_server, current_capacity, preferred_district = rpc_find_available(node_profile, district_uuid, require_specific_district)
        if !current_server
          current_server, current_capacity, preferred_district = rpc_find_available(node_profile, district_uuid, require_specific_district, true)
        end
        district = preferred_district if preferred_district
        Rails.logger.debug "CURRENT SERVER: #{current_server}"
        raise OpenShift::NodeException.new("No nodes available.", 140) unless current_server
        Rails.logger.debug "DEBUG: find_available_impl: current_server: #{current_server}: #{current_capacity}"

        MCollectiveApplicationContainerProxy.new(current_server, district)
      end
      
      def self.find_one_impl(node_profile=nil)
        current_server = rpc_find_one(node_profile)
        Rails.logger.debug "CURRENT SERVER: #{current_server}"
        raise OpenShift::NodeException.new("No nodes found.", 140) unless current_server
        Rails.logger.debug "DEBUG: find_one_impl: current_server: #{current_server}"

        MCollectiveApplicationContainerProxy.new(current_server)
      end

      def self.get_blacklisted_in_impl
        []
      end

      def self.blacklisted_in_impl?(name)
        false
      end
      
      def get_available_cartridges
        args = Hash.new
        args['--porcelain'] = true
        args['--with-descriptors'] = true
        result = execute_direct(@@C_CONTROLLER, 'cartridge-list', args, false)
        result = parse_result(result)
        cart_data = JSON.parse(result.resultIO.string)
        cart_data.map! {|c| OpenShift::Cartridge.new.from_descriptor(YAML.load(c))}
      end

      # Returns an array with following information
      # [Filesystem, blocks_used, blocks_soft_limit, blocks_hard_limit, inodes_used,
      #  inodes_soft_limit, inodes_hard_limit]
      def get_quota(gear)
        args = Hash.new
        args['--uuid'] = gear.uuid
        reply = execute_direct(@@C_CONTROLLER, 'get-quota', args, false)

        output = nil
        exitcode = 0
        if reply.length > 0
          mcoll_result = reply[0]
          if (mcoll_result && (defined? mcoll_result.results) && !mcoll_result.results[:data].nil?)
            output = mcoll_result.results[:data][:output]
            exitcode = mcoll_result.results[:data][:exitcode]
            raise OpenShift::NodeException.new("Failed to get quota for user: #{output}", 143) unless exitcode == 0
          else
            raise OpenShift::NodeException.new("Node execution failure (error getting result from node).  If the problem persists please contact Red Hat support.", 143)
          end
        else
          raise OpenShift::NodeException.new("Node execution failure (error getting result from node).  If the problem persists please contact Red Hat support.", 143)
        end
        output
      end
      
      # Set blocks hard limit and inodes ihard limit for uuid
      def set_quota(gear, storage_in_gb, inodes)
        args = Hash.new
        args['--uuid']   = gear.uuid
        # quota command acts on 1K blocks
        args['--blocks'] = Integer(storage_in_gb * 1024 * 1024)
        args['--inodes'] = inodes unless inodes.nil?
        reply = execute_direct(@@C_CONTROLLER, 'set-quota', args, false)

        output = nil
        exitcode = 0
        if reply.length > 0
          mcoll_result = reply[0]
          if (mcoll_result && (defined? mcoll_result.results) && !mcoll_result.results[:data].nil?)
            output = mcoll_result.results[:data][:output]
            exitcode = mcoll_result.results[:data][:exitcode]
            raise OpenShift::NodeException.new("Failed to set quota for user: #{output}", 143) unless exitcode == 0
          else
            raise OpenShift::NodeException.new("Node execution failure (error getting result from node).  If the problem persists please contact Red Hat support.", 143)
          end
        else
          raise OpenShift::NodeException.new("Node execution failure (error getting result from node).  If the problem persists please contact Red Hat support.", 143)
        end
      end

      def reserve_uid(district_uuid=nil)
        reserved_uid = nil
        if Rails.configuration.msg_broker[:districts][:enabled]
          if @district
            district_uuid = @district.uuid
          else
            district_uuid = get_district_uuid unless district_uuid
          end
          if district_uuid && district_uuid != 'NONE'
            reserved_uid = OpenShift::DataStore.instance.reserve_district_uid(district_uuid)
            raise OpenShift::OOException.new("uid could not be reserved") unless reserved_uid
          end
        end
        reserved_uid
      end
      
      def unreserve_uid(uid, district_uuid=nil)
        if Rails.configuration.msg_broker[:districts][:enabled]
          if @district
            district_uuid = @district.uuid
          else
            district_uuid = get_district_uuid unless district_uuid
          end
          if district_uuid && district_uuid != 'NONE'
            OpenShift::DataStore.instance.unreserve_district_uid(district_uuid, uid)
          end
        end
      end
      
      def inc_externally_reserved_uids_size(district_uuid=nil)
        if Rails.configuration.msg_broker[:districts][:enabled]
          if @district
            district_uuid = @district.uuid
          else
            district_uuid = get_district_uuid unless district_uuid
          end
          if district_uuid && district_uuid != 'NONE'
            OpenShift::DataStore.instance.inc_district_externally_reserved_uids_size(district_uuid)
          end
        end
      end
      
      def create(app, gear, quota_blocks=nil, quota_files=nil)
        result = nil
        (1..10).each do |i|
          args = Hash.new
          args['--with-app-uuid'] = app.uuid
          args['--with-app-name'] = app.name
          args['--with-container-uuid'] = gear.uuid
          args['--with-container-name'] = gear.name
          args['--with-quota-blocks'] = quota_blocks if quota_blocks
          args['--with-quota-files'] = quota_files if quota_files
          args['--with-namespace'] = app.domain.namespace
          args['--with-uid'] = gear.uid if gear.uid
          mcoll_reply = execute_direct(@@C_CONTROLLER, 'app-create', args)
          result = parse_result(mcoll_reply)
          if result.exitcode == 129 && has_uid_or_gid?(app.gear.uid) # Code to indicate uid already taken
            destroy(app, gear, true)
            inc_externally_reserved_uids_size
            gear.uid = reserve_uid
            app.save
          else
            break
          end
        end
        result
      end
    
      def destroy(app, gear, keep_uid=false, uid=nil, skip_hooks=false)
        args = Hash.new
        args['--with-app-uuid'] = app.uuid
        args['--with-app-name'] = app.name
        args['--with-container-uuid'] = gear.uuid
        args['--with-container-name'] = gear.name
        args['--with-namespace'] = app.domain.namespace
        args['--skip-hooks'] = true if skip_hooks
        result = execute_direct(@@C_CONTROLLER, 'app-destroy', args)
        result_io = parse_result(result)

        uid = gear.uid unless uid
        
        if uid && !keep_uid
          unreserve_uid(uid)
        end
        return result_io
      end

      def add_ssl_cert(app, gear, ssl_cert, ssl_cert_name, priv_key,
                       priv_key_name, server_alias)
        args = Hash.new
        args['--with-app-uuid']       = app.uuid
        args['--with-container-uuid'] = gear.uuid
        args['--with-namespace']      = app.domain.namespace
        args['--with-ssl-cert']       = ssl_cert
        args['--with-ssl-cert-name']  = ssl_cert_name
        args['--with-priv-key']       = priv_key
        args['--with-priv-key-name']  = priv_key_name
        args['--with-alias-name']     = server_alias
        result = execute_direct(@@C_CONTROLLER, 'ssl-cert-add', args)
        parse_result(result)
      end

      def remove_ssl_cert(app, gear, ssl_cert_name, priv_key_name, server_alias)
        args = Hash.new
        args['--with-app-uuid']       = app.uuid
        args['--with-container-uuid'] = gear.uuid
        args['--with-namespace']      = app.domain.namespace
        args['--with-ssl-cert-name']  = ssl_cert_name
        args['--with-priv-key-name']  = priv_key_name
        args['--with-alias-name']     = server_alias
        result = execute_direct(@@C_CONTROLLER, 'ssl-cert-remove', args)
        parse_result(result)
      end

      def add_authorized_ssh_key(app, gear, ssh_key, key_type=nil, comment=nil)
        args = Hash.new
        args['--with-app-uuid'] = app.uuid
        args['--with-container-uuid'] = gear.uuid
        args['--with-ssh-key'] = ssh_key
        args['--with-ssh-key-type'] = key_type if key_type
        args['--with-ssh-key-comment'] = comment if comment
        result = execute_direct(@@C_CONTROLLER, 'authorized-ssh-key-add', args)
        parse_result(result)
      end

      def remove_authorized_ssh_key(app, gear, ssh_key, comment=nil)
        args = Hash.new
        args['--with-app-uuid'] = app.uuid
        args['--with-container-uuid'] = gear.uuid
        args['--with-ssh-key'] = ssh_key
        args['--with-ssh-comment'] = comment if comment
        result = execute_direct(@@C_CONTROLLER, 'authorized-ssh-key-remove', args)
        parse_result(result)
      end

      def add_env_var(app, gear, key, value)
        args = Hash.new
        args['--with-app-uuid'] = app.uuid
        args['--with-container-uuid'] = gear.uuid
        args['--with-key'] = key
        args['--with-value'] = value
        result = execute_direct(@@C_CONTROLLER, 'env-var-add', args)
        parse_result(result)
      end
      
      def remove_env_var(app, gear, key)
        args = Hash.new
        args['--with-app-uuid'] = app.uuid
        args['--with-container-uuid'] = gear.uuid
        args['--with-key'] = key
        result = execute_direct(@@C_CONTROLLER, 'env-var-remove', args)
        parse_result(result)
      end
    
      def add_broker_auth_key(app, gear, iv, token)
        args = Hash.new
        args['--with-app-uuid'] = app.uuid
        args['--with-container-uuid'] = gear.uuid
        args['--with-iv'] = iv
        args['--with-token'] = token
        result = execute_direct(@@C_CONTROLLER, 'broker-auth-key-add', args)
        parse_result(result)
      end
    
      def remove_broker_auth_key(app, gear)
        args = Hash.new
        args['--with-app-uuid'] = app.uuid
        args['--with-container-uuid'] = gear.uuid
        result = execute_direct(@@C_CONTROLLER, 'broker-auth-key-remove', args)
        parse_result(result)
      end

      def show_state(app, gear)
        args = Hash.new
        args['--with-app-uuid'] = app.uuid
        args['--with-container-uuid'] = gear.uuid
        result = execute_direct(@@C_CONTROLLER, 'app-state-show', args)
        parse_result(result)
      end
      
      def configure_cartridge(app, gear, cart, template_git_url=nil)
        result_io = ResultIO.new
        cart_data = nil
                  
        if framework_carts.include? cart
          result_io = run_cartridge_command(cart, app, gear, "configure", template_git_url)
        elsif embedded_carts.include? cart
          result_io, cart_data = add_component(app,gear,cart)
        else
          #no-op
        end
        
        return result_io, cart_data
      end
      
      def deconfigure_cartridge(app, gear, cart)
        if framework_carts.include? cart
          run_cartridge_command(cart, app, gear, "deconfigure")
        elsif embedded_carts.include? cart
          remove_component(app,gear,cart)
        else
          ResultIO.new
        end        
      end
      
      def get_public_hostname
        rpc_get_fact_direct('public_hostname')
      end
      
      def get_capacity
        rpc_get_fact_direct('capacity').to_f
      end
      
      def get_active_capacity
        rpc_get_fact_direct('active_capacity').to_f
      end
      
      def get_district_uuid
        rpc_get_fact_direct('district_uuid')
      end
      
      def get_ip_address
        rpc_get_fact_direct('ipaddress')
      end
      
      def get_public_ip_address
        rpc_get_fact_direct('public_ip')
      end
      
      def get_node_profile
        rpc_get_fact_direct('node_profile')
      end

      def get_quota_blocks
        rpc_get_fact_direct('quota_blocks')
      end

      def get_quota_files
        rpc_get_fact_direct('quota_files')
      end

      def execute_connector(app, gear, cart, connector_name, input_args)
        args = Hash.new
        args['--gear-uuid'] = gear.uuid
        args['--cart-name'] = cart
        args['--hook-name'] = connector_name
        args['--input-args'] = input_args.join(" ")
        mcoll_reply = execute_direct(@@C_CONTROLLER, 'connector-execute', args)
        if mcoll_reply and mcoll_reply.length>0
          mcoll_reply = mcoll_reply[0]
          output = mcoll_reply.results[:data][:output]
          exitcode = mcoll_reply.results[:data][:exitcode]
          return [output, exitcode]
        end
        [nil, nil]
      end
      
      def start(app, gear, cart)
        if framework_carts.include?(cart)
          run_cartridge_command(cart, app, gear, "start")
        elsif embedded_carts.include? cart
          start_component(app, gear, cart)
        else
          ResultIO.new
        end
      end
      
      def stop(app, gear, cart)
        if framework_carts.include?(cart)
          run_cartridge_command(cart, app, gear, "stop")
        elsif embedded_carts.include? cart
          stop_component(app, gear, cart)
        else
          ResultIO.new          
        end
      end
      
      def force_stop(app, gear, cart)
        args = Hash.new
        args['--with-app-uuid'] = app.uuid
        args['--with-container-uuid'] = gear.uuid
        result = execute_direct(@@C_CONTROLLER, 'force-stop', args)
        parse_result(result)
      end
      
      def restart(app, gear, cart)
        if framework_carts.include?(cart)
          run_cartridge_command(cart, app, gear, "restart")
        elsif embedded_carts.include? cart
          restart_component(app, gear, cart)
        else
          ResultIO.new                  
        end
      end
      
      def reload(app, gear, cart)
        if framework_carts.include?(cart)
          run_cartridge_command(cart, app, gear, "reload")
        elsif embedded_carts.include? cart
          reload_component(app, gear, cart)
        else
          ResultIO.new          
        end
      end
 
      def status(app, gear, cart)
        if framework_carts.include?(cart)
          run_cartridge_command(cart, app, gear, "status")
        elsif embedded_carts.include? cart
          component_status(app, gear, cart)
        else
          ResultIO.new          
        end
      end
 
      def tidy(app, gear, cart)
        args = Hash.new
        args['--with-app-uuid'] = app.uuid
        args['--with-container-uuid'] = gear.uuid
        result = execute_direct(@@C_CONTROLLER, 'tidy', args)
        parse_result(result)
      end
      
      def threaddump(app, gear, cart)
        if framework_carts.include?(cart)
          run_cartridge_command(cart, app, gear, "threaddump")
        else
          ResultIO.new
        end          
      end
      
      def system_messages(app, gear, cart)
        if framework_carts.include?(cart)
          run_cartridge_command(cart, app, gear, "system-messages")
        else
          ResultIO.new
        end          
      end
      
      def expose_port(app, gear, cart)
        run_cartridge_command(cart, app, gear, "expose-port")
      end

      def conceal_port(app, gear, cart)
        run_cartridge_command(cart, app, gear, "conceal-port")
      end

      def show_port(app, gear, cart)
        run_cartridge_command(cart, app, gear, "show-port")
      end

      def add_alias(app, gear, server_alias)
        args = Hash.new
        args['--with-container-uuid']=gear.uuid
        args['--with-container-name']=gear.name
        args['--with-namespace']=app.domain.namespace
        args['--with-alias-name']=server_alias
        result = execute_direct(@@C_CONTROLLER, 'add-alias', args)
        parse_result(result)
      end
      
      def remove_alias(app, gear, server_alias)
        args = Hash.new
        args['--with-container-uuid']=gear.uuid
        args['--with-container-name']=gear.name
        args['--with-namespace']=app.domain.namespace
        args['--with-alias-name']=server_alias
        result = execute_direct(@@C_CONTROLLER, 'remove-alias', args)
        parse_result(result)        
      end
      
      def update_namespace(app, gear, cart, new_ns, old_ns)
        mcoll_reply = execute_direct(cart, 'update-namespace', "#{gear.name} #{new_ns} #{old_ns} #{gear.uuid}")
        parse_result(mcoll_reply)
      end

      def get_env_var_add_job(app, gear, key, value)
        args = Hash.new
        args['--with-app-uuid'] = app.uuid
        args['--with-container-uuid'] = gear.uuid
        args['--with-key'] = key
        args['--with-value'] = value
        job = RemoteJob.new('openshift-origin-node', 'env-var-add', args)
        job
      end
      
      def get_env_var_remove_job(app, gear, key)
        args = Hash.new
        args['--with-app-uuid'] = app.uuid
        args['--with-container-uuid'] = gear.uuid
        args['--with-key'] = key
        job = RemoteJob.new('openshift-origin-node', 'env-var-remove', args)
        job
      end
  
      def get_add_authorized_ssh_key_job(app, gear, ssh_key, key_type=nil, comment=nil)
        args = Hash.new
        args['--with-app-uuid'] = app.uuid
        args['--with-container-uuid'] = gear.uuid
        args['--with-ssh-key'] = ssh_key
        args['--with-ssh-key-type'] = key_type if key_type
        args['--with-ssh-key-comment'] = comment if comment
        job = RemoteJob.new('openshift-origin-node', 'authorized-ssh-key-add', args)
        job
      end
      
      def get_remove_authorized_ssh_key_job(app, gear, ssh_key, comment=nil)
        args = Hash.new
        args['--with-app-uuid'] = app.uuid
        args['--with-container-uuid'] = gear.uuid
        args['--with-ssh-key'] = ssh_key
        args['--with-ssh-comment'] = comment if comment
        job = RemoteJob.new('openshift-origin-node', 'authorized-ssh-key-remove', args)
        job
      end

      def get_broker_auth_key_add_job(app, gear, iv, token)
        args = Hash.new
        args['--with-app-uuid'] = app.uuid
        args['--with-container-uuid'] = gear.uuid
        args['--with-iv'] = iv
        args['--with-token'] = token
        job = RemoteJob.new('openshift-origin-node', 'broker-auth-key-add', args)
        job
      end
  
      def get_broker_auth_key_remove_job(app, gear)
        args = Hash.new
        args['--with-app-uuid'] = app.uuid
        args['--with-container-uuid'] = gear.uuid
        job = RemoteJob.new('openshift-origin-node', 'broker-auth-key-remove', args)
        job
      end

      def get_execute_connector_job(app, gear, cart, connector_name, input_args)
        args = Hash.new
        args['--gear-uuid'] = gear.uuid
        args['--cart-name'] = cart
        args['--hook-name'] = connector_name
        args['--input-args'] = input_args.join(" ")
        job = RemoteJob.new('openshift-origin-node', 'connector-execute', args)
        job
      end

      def get_show_state_job(app, gear)
        args = Hash.new
        args['--with-app-uuid'] = app.uuid
        args['--with-container-uuid'] = gear.uuid
        job = RemoteJob.new('openshift-origin-node', 'app-state-show', args)
        job
      end

      def get_status_job(app, gear, cart)
        args = "'#{gear.name}' '#{app.domain.namespace}' '#{gear.uuid}'"
        job = RemoteJob.new(cart, 'status', args)
        job
      end

      def get_show_gear_quota_job(gear)
        args = Hash.new
        args['--uuid'] = gear.uuid
        job = RemoteJob.new('openshift-origin-node', 'get-quota', args)
        job
      end
      
      def get_update_gear_quota_job(gear, storage_in_gb, inodes)
        args = Hash.new
        args['--uuid']   = gear.uuid
        # quota command acts on 1K blocks
        args['--blocks'] = Integer(storage_in_gb * 1024 * 1024)
        args['--inodes'] = inodes unless inodes.to_s.empty?
        job = RemoteJob.new('openshift-origin-node', 'set-quota', args)
        job
      end
      
      def move_gear_post(app, gear, destination_container, state_map, keep_uid)
        reply = ResultIO.new
        source_container = gear.container
        gi = app.group_instance_map[gear.group_instance_name]
        app.start_order.each do |ci_name|
          next if not gi.component_instances.include? ci_name
          cinst = app.comp_instance_map[ci_name]
          cart = cinst.parent_cart_name
          next if cart==app.name
          idle, leave_stopped = state_map[ci_name]
          unless leave_stopped
            log_debug "DEBUG: Starting cartridge '#{cart}' in '#{app.name}' after move on #{destination_container.id}"
            reply.append destination_container.send(:run_cartridge_command, cart, app, gear, "start", nil, false)
          end
        end

        log_debug "DEBUG: Fixing DNS and mongo for gear '#{gear.name}' after move"
        log_debug "DEBUG: Changing server identity of '#{gear.name}' from '#{source_container.id}' to '#{destination_container.id}'"
        gear.server_identity = destination_container.id
        gear.container = destination_container
        if app.scalable and not gi.component_instances.find { |cart| cart.include? app.proxy_cartridge }
          dns = OpenShift::DnsService.instance
          begin
            public_hostname = destination_container.get_public_hostname
            dns.modify_application(gear.name, app.domain.namespace, public_hostname)
            dns.publish
          ensure
            dns.close
          end
        end

        if (not app.scalable) or (app.scalable and gi.component_instances.find { |cart| cart.include? app.proxy_cartridge } )
          unless keep_uid
            unless app.aliases.nil?
              app.aliases.each do |server_alias|
                reply.append destination_container.add_alias(app, app.gear, server_alias)
              end
            end
          end
          app.recreate_dns
        end

        reply
      end

      def move_gear_pre(app, gear, state_map, keep_uid)
        reply = ResultIO.new
        source_container = gear.container
        gi = app.group_instance_map[gear.group_instance_name]
        app.start_order.reverse.each { |ci_name|
          next if not gi.component_instances.include? ci_name
          cinst = app.comp_instance_map[ci_name]
          cart = cinst.parent_cart_name
          next if cart==app.name
          idle, leave_stopped = state_map[ci_name]
          # stop the cartridge if it needs to
          unless leave_stopped
            log_debug "DEBUG: Stopping existing app cartridge '#{cart}' before moving"
            do_with_retry('stop') do
              reply.append source_container.stop(app, gear, cart)
            end
            if framework_carts.include? cart
              log_debug "DEBUG: Force stopping existing app cartridge '#{cart}' before moving"
              do_with_retry('force-stop') do
                reply.append source_container.force_stop(app, gear, cart)
              end
            end
          end
          # execute pre_move
          if embedded_carts.include? cart and not keep_uid
            if (app.scalable and not cart.include? app.proxy_cartridge) or not app.scalable
              log_debug "DEBUG: Performing cartridge level pre-move for embedded #{cart} for '#{app.name}' on #{source_container.id}"
              reply.append source_container.send(:run_cartridge_command, "embedded/" + cart, app, gear, "pre-move", nil, false)
            end
          end
        }
        reply
      end

      def move_gear(app, gear, destination_container, destination_district_uuid, allow_change_district, node_profile)
        reply = ResultIO.new
        state_map = {}
        gear.node_profile = node_profile if node_profile
        orig_uid = gear.uid

        # resolve destination_container according to district
        destination_container, destination_district_uuid, keep_uid = resolve_destination(app, gear, destination_container, destination_district_uuid, allow_change_district)

        source_container = gear.container
        destination_node_profile = destination_container.get_node_profile
        if app.scalable and source_container.get_node_profile != destination_node_profile
          log_debug "Cannot change node_profile for a gear belonging to a scalable application. The destination container's node profile is #{destination_node_profile}, while the gear's node_profile is #{gear.node_profile}"
          raise OpenShift::UserException.new("Error moving app.  Cannot change node profile.", 1)
        end

        # get the state of all cartridges
        quota_blocks = nil
        quota_files = nil
        idle, leave_stopped, quota_blocks, quota_files = get_app_status(app)
        gi = app.group_instance_map[gear.group_instance_name]
        gi.component_instances.each do |ci_name|
          cinst = app.comp_instance_map[ci_name]
          cart = cinst.parent_cart_name
          next if cart == app.name
          # idle, leave_stopped, quota_blocks, quota_files = get_cart_status(app, gear, cart)
          state_map[ci_name] = [idle, leave_stopped]
        end

        begin
          # pre-move
          reply.append move_gear_pre(app, gear, state_map, keep_uid)

          unless keep_uid
            gear.uid = destination_container.reserve_uid(destination_district_uuid)
            log_debug "DEBUG: Reserved uid '#{gear.uid}' on district: '#{destination_district_uuid}'"
          end
          begin
            # rsync gear with destination container
            rsync_destination_container(app, gear, destination_container, destination_district_uuid, quota_blocks, quota_files, orig_uid, keep_uid)

            # now execute 'move'/'expose-port' hooks on the new nest of the components
            app.configure_order.each do |ci_name|
              next if not gi.component_instances.include?(ci_name)
              cinst = app.comp_instance_map[ci_name]
              cart = cinst.parent_cart_name
              next if cart == app.name
              idle, leave_stopped = state_map[ci_name]
              if keep_uid
                if framework_carts.include?(cart)
                  log_debug "DEBUG: Restarting httpd proxy for '#{cart}' on #{destination_container.id}"
                  reply.append destination_container.send(:run_cartridge_command, 'abstract', app, gear, "restart-httpd-proxy", nil, false)
                end
              else
                if embedded_carts.include?(cart)
                  if app.scalable and cart.include? app.proxy_cartridge
                    log_debug "DEBUG: Performing cartridge level move for '#{cart}' on #{destination_container.id}"
                    reply.append destination_container.send(:run_cartridge_command, cart, app, gear, "move", idle ? '--idle' : nil, false)
                  else
                    log_debug "DEBUG: Performing cartridge level move for embedded #{cart} for '#{app.name}' on #{destination_container.id}"
                    embedded_reply = destination_container.send(:run_cartridge_command, "embedded/" + cart, app, gear, "move", nil, false)
                    component_details = embedded_reply.appInfoIO.string
                    unless component_details.empty?
                      app.set_embedded_cart_info(cart, component_details)
                    end
                    reply.append embedded_reply
                    log_debug "DEBUG: Performing cartridge level post-move for embedded #{cart} for '#{app.name}' on #{destination_container.id}"
                    reply.append destination_container.send(:run_cartridge_command, "embedded/" + cart, app, gear, "post-move", nil, false)
                  end
                end
                if framework_carts.include?(cart)
                  log_debug "DEBUG: Performing cartridge level move for '#{cart}' on #{destination_container.id}"
                  reply.append destination_container.send(:run_cartridge_command, cart, app, gear, "move", idle ? '--idle' : nil, false)
                end
              end
              if app.scalable and not cart.include? app.proxy_cartridge
                begin
                  reply.append destination_container.expose_port(app, gear, cinst.parent_cart_name)
                rescue Exception=>e
                  # just pass because some embedded cartridges do not have expose-port hook implemented (e.g. jenkins-client)
                end
              end
            end 

            # start the gears again and change DNS entry
            reply.append move_gear_post(app, gear, destination_container, state_map, keep_uid)
            app.elaborate_descriptor
            app.execute_connections
            if app.scalable
              # execute connections restart the haproxy service, so stop it explicitly if needed
              app.start_order.reverse.each do |ci_name|
                next if not gi.component_instances.include? ci_name
                cinst = app.comp_instance_map[ci_name]
                cart = cinst.parent_cart_name
                next if cart==app.name
                idle, leave_stopped = state_map[ci_name]
                if leave_stopped and cart.include? app.proxy_cartridge
                  log_debug "DEBUG: Explicitly stopping cartridge '#{cart}' in '#{app.name}' after move on #{destination_container.id}"
                  reply.append destination_container.stop(app, gear, cart)
                end
              end
            end
            if gear.node_profile != destination_node_profile
              log_debug "DEBUG: The gear's node profile changed from #{gear.node_profile} to #{destination_node_profile}"
              gear.node_profile = destination_node_profile
              if not app.scalable
                app.node_profile = destination_node_profile 
                gi.node_profile = destination_node_profile
              end
            end
            app.save

          rescue Exception => e
            gear.container = source_container
            # remove-httpd-proxy of destination
            log_debug "DEBUG: Moving failed.  Rolling back gear '#{gear.name}' '#{app.name}' with remove-httpd-proxy on '#{destination_container.id}'"
            gi.component_instances.each do |ci_name|
              cinst = app.comp_instance_map[ci_name]
              cart = cinst.parent_cart_name
              next if cart == app.name
              if framework_carts.include? cart
                begin
                  reply.append destination_container.send(:run_cartridge_command, cart, app, gear, "remove-httpd-proxy", nil, false)
                rescue Exception => e
                  log_debug "DEBUG: Remove httpd proxy with cart '#{cart}' failed on '#{destination_container.id}'  - gear: '#{gear.name}', app: '#{app.name}'"
                end
              end
            end
            # destroy destination
            log_debug "DEBUG: Moving failed.  Rolling back gear '#{gear.name}' in '#{app.name}' with destroy on '#{destination_container.id}'"
            reply.append destination_container.destroy(app, gear, keep_uid, nil, true)
            raise
          end
        rescue Exception => e
          begin
            unless keep_uid
              # post_move source
              gi.component_instances.each do |ci_name|
                cinst = app.comp_instance_map[ci_name]
                cart = cinst.parent_cart_name
                next if cart==app.name
                proxy_cart = (app.proxy_cartridge or "")
                if embedded_carts.include? cart and not cart.include? proxy_cart
                  begin
                    log_debug "DEBUG: Performing cartridge level post-move for embedded #{cart} for '#{app.name}' on #{source_container.id}"
                    reply.append source_container.send(:run_cartridge_command, "embedded/" + cart, app, gear, "post-move", nil, false)
                  rescue Exception => e
                    log_error "ERROR: Error performing cartridge level post-move for embedded #{cart} for '#{app.name}' on #{source_container.id}: #{e.message}"
                  end
                end
              end
            end
            # start source
            gi.component_instances.each do |ci_name|
              cinst = app.comp_instance_map[ci_name]
              cart = cinst.parent_cart_name
              next if cart==app.name
              idle, leave_stopped = state_map[ci_name]
              if not leave_stopped
                reply.append source_container.run_cartridge_command(cart, app, gear, "start", nil, false) if framework_carts.include? cart
              end
            end
          ensure
            raise
          end
        end

        move_gear_destroy_old(app, gear, keep_uid, orig_uid, source_container, destination_container)

        log_debug "Successfully moved '#{app.name}' with gear uuid '#{gear.uuid}' from '#{source_container.id}' to '#{destination_container.id}'"
        reply
      end

      def move_gear_destroy_old(app, gear, keep_uid, orig_uid, source_container, destination_container)
        reply = ResultIO.new
        log_debug "DEBUG: Deconfiguring old app '#{app.name}' on #{source_container.id} after move"
        begin
          reply.append source_container.destroy(app, gear, keep_uid, orig_uid, true)
        rescue Exception => e
          log_debug "DEBUG: The application '#{app.name}' with gear uuid '#{gear.uuid}' is now moved to '#{destination_container.id}' but not completely deconfigured from '#{source_container.id}'"
          raise
        end
        reply
      end

      def resolve_destination(app, gear, destination_container, destination_district_uuid, allow_change_district)
        source_container = gear.container
        source_container = gear.get_proxy if source_container.nil? 
        source_district_uuid = source_container.get_district_uuid
        if destination_container.nil?
          unless allow_change_district
            if destination_district_uuid && destination_district_uuid != source_district_uuid
              raise OpenShift::UserException.new("Error moving app.  Cannot change district from '#{source_district_uuid}' to '#{destination_district_uuid}' without allow_change_district flag.", 1)
            else
              destination_district_uuid = source_district_uuid unless source_district_uuid == 'NONE'
            end
          end
          destination_container = MCollectiveApplicationContainerProxy.find_available_impl(gear.node_profile, destination_district_uuid)
          log_debug "DEBUG: Destination container: #{destination_container.id}"
          destination_district_uuid = destination_container.get_district_uuid
        else
          if destination_district_uuid
            log_debug "DEBUG: Destination district uuid '#{destination_district_uuid}' is being ignored in favor of destination container #{destination_container.id}"
          end
          destination_district_uuid = destination_container.get_district_uuid
          unless allow_change_district || (source_district_uuid == destination_district_uuid)
            raise OpenShift::UserException.new("Resulting move would change districts from '#{source_district_uuid}' to '#{destination_district_uuid}'.  You can use the 'allow_change_district' option if you really want this to happen.", 1)
          end
        end
        
        log_debug "DEBUG: Source district uuid: #{source_district_uuid}"
        log_debug "DEBUG: Destination district uuid: #{destination_district_uuid}"
        keep_uid = destination_district_uuid == source_district_uuid && destination_district_uuid && destination_district_uuid != 'NONE'
        log_debug "DEBUG: District unchanged keeping uid" if keep_uid

        if source_container.id == destination_container.id
          raise OpenShift::UserException.new("Error moving app.  Old and new servers are the same: #{source_container.id}", 1)
        end
        return [destination_container, destination_district_uuid, keep_uid]
      end

      def rsync_destination_container(app, gear, destination_container, destination_district_uuid, quota_blocks, quota_files, orig_uid, keep_uid)
        reply = ResultIO.new
        source_container = gear.container
        log_debug "DEBUG: Creating new account for gear '#{gear.name}' on #{destination_container.id}"
        reply.append destination_container.create(app, gear, quota_blocks, quota_files)

        log_debug "DEBUG: Moving content for app '#{app.name}', gear '#{gear.name}' to #{destination_container.id}"
        rsync_keyfile = Rails.configuration.auth[:rsync_keyfile]
        log_debug `eval \`ssh-agent\`; ssh-add #{rsync_keyfile}; ssh -o StrictHostKeyChecking=no -A root@#{source_container.get_ip_address} "rsync -aA#{(gear.uid && gear.uid == orig_uid) ? 'X' : ''} -e 'ssh -o StrictHostKeyChecking=no' /var/lib/openshift/#{gear.uuid}/ root@#{destination_container.get_ip_address}:/var/lib/openshift/#{gear.uuid}/"; exit_code=$?; ssh-agent -k; exit $exit_code`
        if $?.exitstatus != 0
          raise OpenShift::NodeException.new("Error moving app '#{app.name}', gear '#{gear.name}' from #{source_container.id} to #{destination_container.id}", 143)
        end

        if keep_uid
          log_debug "DEBUG: Moving system components for app '#{app.name}', gear '#{gear.name}' to #{destination_container.id}"
          log_debug `eval \`ssh-agent\`; ssh-add #{rsync_keyfile}; ssh -o StrictHostKeyChecking=no -A root@#{source_container.get_ip_address} "rsync -aAX -e 'ssh -o StrictHostKeyChecking=no' --include '.httpd.d/' --include '.httpd.d/#{gear.uuid}_***' --include '#{app.name}-#{app.domain.namespace}' --include '.last_access/' --include '.last_access/#{gear.uuid}' --exclude '*' /var/lib/openshift/ root@#{destination_container.get_ip_address}:/var/lib/openshift/"; exit_code=$?; ssh-agent -k; exit $exit_code`
          if $?.exitstatus != 0
            raise OpenShift::NodeException.new("Error moving system components for app '#{app.name}', gear '#{gear.name}' from #{source_container.id} to #{destination_container.id}", 143)
          end
        end
        reply
      end

      def get_app_status(app)
        get_cart_status(app, app.gear, app.framework)
      end

      def get_cart_status(app, gear, cart_name)
        reply = ResultIO.new
        source_container = gear.container
        leave_stopped = false
        idle = false
        quota_blocks = nil
        quota_files = nil
        log_debug "DEBUG: Getting existing app '#{app.name}' status before moving"
        do_with_retry('status') do
          result = source_container.status(app, gear, cart_name)
          result.cart_commands.each do |command_item|
            case command_item[:command]
            when "ATTR"
              key = command_item[:args][0]
              value = command_item[:args][1]
              if key == 'status'
                case value
                when "ALREADY_STOPPED"
                  leave_stopped = true
                when "ALREADY_IDLED"
                  leave_stopped = true
                  idle = true
                end
              elsif key == 'quota_blocks'
                quota_blocks = value
              elsif key == 'quota_files'
                quota_files = value
              end
            end
            reply.append result
          end
        end

        if idle
          log_debug "DEBUG: Gear component '#{cart_name}' was idle"
        elsif leave_stopped
          log_debug "DEBUG: Gear component '#{cart_name}' was stopped"
        else
          log_debug "DEBUG: Gear component '#{cart_name}' was running"
        end

        return [idle, leave_stopped, quota_blocks, quota_files]
      end

      #
      # Execute an RPC call for the specified agent.
      # If a server is supplied, only execute for that server.
      #
      def self.rpc_exec(agent, server=nil, forceRediscovery=false, options=rpc_options)
      
        # Setup the rpc client
        rpc_client = rpcclient(agent, :options => options)

        # Filter to the specified server
        if server
          Rails.logger.debug("DEBUG: rpc_exec: Filtering rpc_exec to server #{server}")
          rpc_client.identity_filter(server)
        end

        if forceRediscovery
          rpc_client.reset
        end
        Rails.logger.debug("DEBUG: rpc_exec: rpc_client=#{rpc_client}")
      
        # Execute a block and make sure we disconnect the client
        begin
          result = yield rpc_client
        ensure
          rpc_client.disconnect
        end

        raise OpenShift::NodeException.new("Node execution failure (error getting result from node).  If the problem persists please contact Red Hat support.", 143) unless result

        result
      end
      
      def set_district(uuid, active)
        mc_args = { :uuid => uuid,
                    :active => active}
        rpc_client = rpc_exec_direct('openshift')
        result = nil
        begin
          Rails.logger.debug "DEBUG: rpc_client.custom_request('set_district', #{mc_args.inspect}, #{@id}, {'identity' => #{@id}})"
          result = rpc_client.custom_request('set_district', mc_args, @id, {'identity' => @id})
          Rails.logger.debug "DEBUG: #{result.inspect}"
        ensure
          rpc_client.disconnect
        end
        Rails.logger.debug result.inspect
        result
      end
      
      protected
      
      def do_with_retry(action, num_tries=2)
        (1..num_tries).each do |i|
          begin
            yield
            if (i > 1)
              log_debug "DEBUG: Action '#{action}' succeeded on try #{i}.  You can ignore previous error messages or following mcollective debug related to '#{action}'"
            end
            break
          rescue Exception => e
            log_debug "DEBUG: Error performing #{action} on existing app on try #{i}: #{e.message}"
            raise if i == num_tries
          end
        end
      end
      
      def framework_carts
        @framework_carts ||= CartridgeCache.cartridge_names('standalone')
      end
      
      def embedded_carts
        @embedded_carts ||= CartridgeCache.cartridge_names('embedded')
      end
      
      def add_component(app, gear, component)
        reply = ResultIO.new
        begin
          reply.append run_cartridge_command('embedded/' + component, app, gear, 'configure')
        rescue Exception => e
          begin
            Rails.logger.debug "DEBUG: Failed to embed '#{component}' in '#{app.name}' for user '#{app.user.login}'"
            reply.debugIO << "Failed to embed '#{component} in '#{app.name}'"
            reply.append run_cartridge_command('embedded/' + component, app, gear, 'deconfigure')
          ensure
            raise
          end
        end
        
        component_details = reply.appInfoIO.string.empty? ? '' : reply.appInfoIO.string
        reply.debugIO << "Embedded app details: #{component_details}"
        [reply, component_details]
      end
      
      def remove_component(app, gear, component)
        Rails.logger.debug "DEBUG: Deconfiguring embedded application '#{component}' in application '#{app.name}' on node '#{@id}'"
        return run_cartridge_command('embedded/' + component, app, gear, 'deconfigure')
      end
      
      def start_component(app, gear, component)
        run_cartridge_command('embedded/' + component, app, gear, "start")
      end
      
      def stop_component(app, gear, component)
        run_cartridge_command('embedded/' + component, app, gear, "stop")
      end
      
      def restart_component(app, gear, component)
        run_cartridge_command('embedded/' + component, app, gear, "restart")    
      end
      
      def reload_component(app, gear, component)
        run_cartridge_command('embedded/' + component, app, gear, "reload")    
      end
      
      def component_status(app, gear, component)
        run_cartridge_command('embedded/' + component, app, gear, "status")    
      end
      
      def log_debug(message)
        Rails.logger.debug message
        puts message
      end
      
      def log_error(message)
        Rails.logger.error message
        puts message
      end
      
      def execute_direct(cartridge, action, args, log_debug_output=true)
          mc_args = { :cartridge => cartridge,
                      :action => action,
                      :args => args }
                      
          rpc_client = rpc_exec_direct('openshift')
          result = nil
          begin
            Rails.logger.debug "DEBUG: rpc_client.custom_request('cartridge_do', #{mc_args.inspect}, #{@id}, {'identity' => #{@id}})"
            result = rpc_client.custom_request('cartridge_do', mc_args, @id, {'identity' => @id})
            Rails.logger.debug "DEBUG: #{result.inspect}" if log_debug_output
          ensure
            rpc_client.disconnect
          end
          result
      end

      def parse_result(mcoll_reply, app=nil, command=nil)
        mcoll_result = mcoll_reply[0]
        output = nil
        if (mcoll_result && (defined? mcoll_result.results) && !mcoll_result.results[:data].nil?)
          output = mcoll_result.results[:data][:output]
          exitcode = mcoll_result.results[:data][:exitcode]
        else
          server_identity = app ? MCollectiveApplicationContainerProxy.find_app(app.uuid, app.name) : nil
          if server_identity && @id != server_identity
            raise OpenShift::InvalidNodeException.new("Node execution failure (invalid  node).  If the problem persists please contact Red Hat support.", 143, nil, server_identity)
          else
            raise OpenShift::NodeException.new("Node execution failure (error getting result from node).  If the problem persists please contact Red Hat support.", 143)
          end
        end
        
        result = MCollectiveApplicationContainerProxy.sanitize_result(output, exitcode)
        #result.exitcode = exitcode

        # raise an exception in case of non-zero exit code from the node
        if result.exitcode != 0
          result.debugIO << "Command return code: " + result.exitcode.to_s
          if result.hasUserActionableError
            raise OpenShift::UserException.new(result.errorIO.string, result.exitcode, result)
          else
            raise OpenShift::NodeException.new("Node execution failure (invalid exit code from node).  If the problem persists please contact Red Hat support.", 143, result)
          end
        end

        result
      end
      
      #
      # Returns the server identity of the specified app
      #
      def self.find_app(app_uuid, app_name)
        server_identity = nil
        rpc_exec('openshift') do |client|
          client.has_app(:uuid => app_uuid,
                         :application => app_name) do |response|
            output = response[:body][:data][:output]
            if output == true
              server_identity = response[:senderid]
            end
          end
        end
        return server_identity
      end
      
      #
      # Returns whether this server has the specified app
      #
      def has_app?(app_uuid, app_name)
        MCollectiveApplicationContainerProxy.rpc_exec('openshift', @id) do |client|
          client.has_app(:uuid => app_uuid,
                         :application => app_name) do |response|
            output = response[:body][:data][:output]
            return output == true
          end
        end
      end
      
      #
      # Returns whether this server has the specified embedded app
      #
      def has_embedded_app?(app_uuid, embedded_type)
        MCollectiveApplicationContainerProxy.rpc_exec('openshift', @id) do |client|
          client.has_embedded_app(:uuid => app_uuid,
                                  :embedded_type => embedded_type) do |response|
            output = response[:body][:data][:output]
            return output == true
          end
        end
      end
      
      #
      # Returns whether this server has already reserved the specified uid as a uid or gid
      #
      def has_uid_or_gid?(uid)
        MCollectiveApplicationContainerProxy.rpc_exec('openshift', @id) do |client|
          client.has_uid_or_gid(:uid => uid.to_s) do |response|
            output = response[:body][:data][:output]
            return output == true
          end
        end
      end
      
      def run_cartridge_command(framework, app, gear, command, arg=nil, allow_move=true)
        resultIO = nil

        arguments = "'#{gear.name}' '#{app.domain.namespace}' '#{gear.uuid}'"
        arguments += " '#{arg}'" if arg

        result = execute_direct(framework, command, arguments)

        begin
          begin
            resultIO = parse_result(result, app, command)
          rescue OpenShift::InvalidNodeException => e
            if command != 'configure' && allow_move
              @id = e.server_identity
              Rails.logger.debug "DEBUG: Changing server identity of '#{gear.name}' from '#{gear.server_identity}' to '#{@id}'"
              dns_service = OpenShift::DnsService.instance
              dns_service.modify_application(gear.name, app.domain.namespace, get_public_hostname)
              dns_service.publish
              gear.server_identity = @id
              app.save
              #retry
              result = execute_direct(framework, command, arguments)
              resultIO = parse_result(result, app, command)
            else
              raise
            end
          end
        rescue OpenShift::NodeException => e
          if command == 'deconfigure'
            if framework.start_with?('embedded/')
              if has_embedded_app?(app.uuid, framework[9..-1])
                raise
              else
                Rails.logger.debug "DEBUG: Component '#{framework}' in application '#{app.name}' not found on node '#{@id}'.  Continuing with deconfigure."
              end
            else
              if has_app?(app.uuid, app.name)
                raise
              else
                Rails.logger.debug "DEBUG: Application '#{app.name}' not found on node '#{@id}'.  Continuing with deconfigure."
              end
            end
          else
            raise
          end
        end

        resultIO
      end
      
      def self.rpc_find_available(node_profile=nil, district_uuid=nil, require_specific_district=false, forceRediscovery=false)
        current_server, current_capacity = nil, nil
        additional_filters = [{:fact => "active_capacity",
                               :value => '100',
                               :operator => "<"}]

        district_uuid = nil if district_uuid == 'NONE'

        if Rails.configuration.msg_broker[:node_profile_enabled]
          if node_profile
            additional_filters.push({:fact => "node_profile",
                                     :value => node_profile,
                                     :operator => "=="})
          end
        end

        if district_uuid
          additional_filters.push({:fact => "district_uuid",
                                   :value => district_uuid,
                                   :operator => "=="})
          additional_filters.push({:fact => "district_active",
                                   :value => true.to_s,
                                   :operator => "=="})
        else
          #TODO how do you filter on a fact not being set
          additional_filters.push({:fact => "district_uuid",
                                   :value => "NONE",
                                   :operator => "=="})

        end
        
        rpc_opts = nil
        unless forceRediscovery
          rpc_opts = rpc_options
          rpc_opts[:disctimeout] = 1
        end

        server_infos = []
        rpc_get_fact('active_capacity', nil, forceRediscovery, additional_filters, rpc_opts) do |server, capacity|
          #Rails.logger.debug "Next server: #{server} active capacity: #{capacity}"
          server_infos << [server, capacity.to_f]
        end

        if !server_infos.empty?
          # Pick a random node amongst the best choices available
          server_infos = server_infos.sort_by { |server_info| server_info[1] }
          if server_infos.first[1] < 80
            # If any server is < 80 then only pick from servers with < 80
            server_infos.delete_if { |server_info| server_info[1] >= 80 }
          end
          max_index = [server_infos.length, 4].min - 1
          server_infos = server_infos.first(max_index + 1)
          # Weight the servers with the most active_capacity the highest 
          (0..max_index).each do |i|
            (max_index - i).times do
              server_infos << server_infos[i]
            end
          end
        elsif district_uuid && !require_specific_district
          # Well that didn't go too well.  They wanted a district.  Probably the most available one.  
          # But it has no available nodes.  Falling back to a best available algorithm.  First
          # Find the most available nodes and match to their districts.  Take out the almost
          # full nodes if possible and return one of the nodes within a district with a lot of space. 
          additional_filters = [{:fact => "active_capacity",
                                 :value => '100',
                                 :operator => "<"},
                                {:fact => "district_active",
                                 :value => true.to_s,
                                 :operator => "=="},
                                {:fact => "district_uuid",
                                 :value => "NONE",
                                 :operator => "!="}]

          if Rails.configuration.msg_broker[:node_profile_enabled]
            if node_profile
              additional_filters.push({:fact => "node_profile",
                                       :value => node_profile,
                                       :operator => "=="})
            end
          end
          
          rpc_opts = nil
          unless forceRediscovery
            rpc_opts = rpc_options
            rpc_opts[:disctimeout] = 1
          end
          districts = District.find_all # candidate for caching
          rpc_get_fact('active_capacity', nil, forceRediscovery, additional_filters, rpc_opts) do |server, capacity|
            districts.each do |district|
              if district.server_identities.has_key?(server)
                server_infos << [server, capacity.to_f, district]
                break
              end
            end
          end
          unless server_infos.empty?
            server_infos = server_infos.sort_by { |server_info| server_info[1] }
            if server_infos.first[1] < 80
              server_infos.delete_if { |server_info| server_info[1] >= 80 }
            end
            server_infos = server_infos.sort_by { |server_info| server_info[2].available_capacity }
            server_infos = server_infos.first(8)
          end
        end
        current_district = nil
        unless server_infos.empty?
          server_info = server_infos[rand(server_infos.length)]
          current_server = server_info[0]
          current_capacity = server_info[1]
          current_district = server_info[2]
          Rails.logger.debug "Current server: #{current_server} active capacity: #{current_capacity}"
        end

        return current_server, current_capacity, current_district
      end
      
      def self.rpc_find_one(node_profile=nil)
        current_server = nil
        additional_filters = []

        if Rails.configuration.msg_broker[:node_profile_enabled]
          if node_profile
            additional_filters.push({:fact => "node_profile",
                                     :value => node_profile,
                                     :operator => "=="})
          end
        end

        options = rpc_options
        options[:filter]['fact'] = options[:filter]['fact'] + additional_filters
        options[:mcollective_limit_targets] = "1"

        rpc_client = rpcclient('rpcutil', :options => options)
        begin
          rpc_client.get_fact(:fact => 'public_hostname') do |response|
            raise OpenShift::NodeException.new("No nodes found.  If the problem persists please contact Red Hat support.", 140) unless Integer(response[:body][:statuscode]) == 0
            current_server = response[:senderid]
          end
        ensure
          rpc_client.disconnect
        end
        return current_server
      end
      
      def self.rpc_options
        # Make a deep copy of the default options
        Marshal::load(Marshal::dump(Rails.configuration.msg_broker[:rpc_options]))
      end
    
      #
      # Return the value of the MCollective response
      # for both a single result and a multiple result
      # structure
      #
      def self.rvalue(response)
        result = nil
    
        if response[:body]
          result = response[:body][:data][:value]
        elsif response[:data]
          result = response[:data][:value]
        end
    
        result
      end
    
      def rsuccess(response)
        response[:body][:statuscode].to_i == 0
      end
    
      #
      # Returns the fact value from the specified server.
      # Yields to the supplied block if there is a non-nil
      # value for the fact.
      #
      def self.rpc_get_fact(fact, server=nil, forceRediscovery=false, additional_filters=nil, custom_rpc_opts=nil)
        result = nil
        options = custom_rpc_opts ? custom_rpc_opts : rpc_options
        options[:filter]['fact'] = options[:filter]['fact'] + additional_filters if additional_filters

        Rails.logger.debug("DEBUG: rpc_get_fact: fact=#{fact}")
        rpc_exec('rpcutil', server, forceRediscovery, options) do |client|
          client.get_fact(:fact => fact) do |response|
            next unless Integer(response[:body][:statuscode]) == 0
    
            # Yield the server and the value to the block
            result = rvalue(response)
            yield response[:senderid], result if result
          end
        end

        result
      end
    
      #
      # Given a known fact and node, get a single fact directly.
      # This is significantly faster then the get_facts method
      # If multiple nodes of the same name exist, it will pick just one
      #
      def rpc_get_fact_direct(fact)
          options = MCollectiveApplicationContainerProxy.rpc_options
    
          rpc_client = rpcclient("rpcutil", :options => options)
          begin
            result = rpc_client.custom_request('get_fact', {:fact => fact}, @id, {'identity' => @id})[0]
            if (result && defined? result.results && result.results.has_key?(:data))
              value = result.results[:data][:value]
            else
              raise OpenShift::NodeException.new("Node execution failure (error getting fact).  If the problem persists please contact Red Hat support.", 143)
            end
          ensure
            rpc_client.disconnect
          end
    
          return value
      end
    
      #
      # Execute direct rpc call directly against a node
      # If more then one node exists, just pick one
      def rpc_exec_direct(agent)
          options = MCollectiveApplicationContainerProxy.rpc_options
          rpc_client = rpcclient(agent, :options => options)
          Rails.logger.debug("DEBUG: rpc_exec_direct: rpc_client=#{rpc_client}")
          rpc_client
      end

      def self.get_all_gears_impl
        gear_map = {}
        sender_map = {}
        rpc_exec('openshift') do |client|
          client.get_all_gears() do |response|
            if response[:body][:statuscode] == 0
              sub_gear_map = response[:body][:data][:output]
              sender = response[:senderid]
              sub_gear_map.each { |k,v|
                gear_map[k] = [sender,Integer(v)]
                sender_map[sender] = {} if not sender_map.has_key? sender
                sender_map[sender][Integer(v)] = k
              }
            end
          end
        end
        return [gear_map, sender_map]
      end

      def self.get_all_active_gears_impl
        active_gears_map = {}
        rpc_exec('openshift') do |client|
          client.get_all_active_gears() do |response|
            if response[:body][:statuscode] == 0
              active_gears = response[:body][:data][:output]
              sender = response[:senderid]
              active_gears_map[sender] = active_gears
            end
          end
        end
        active_gears_map
      end

      def self.sanitize_result(output, exitcode=0)
        result = ResultIO.new
        result.exitcode = exitcode
 
        if output && !output.empty?
          output.each_line do |line|
            if line =~ /^CLIENT_(MESSAGE|RESULT|DEBUG|ERROR|INTERNAL_ERROR): /
              if line =~ /^CLIENT_MESSAGE: /
                result.messageIO << line['CLIENT_MESSAGE: '.length..-1]
              elsif line =~ /^CLIENT_RESULT: /
                result.resultIO << line['CLIENT_RESULT: '.length..-1]
              elsif line =~ /^CLIENT_DEBUG: /
                result.debugIO << line['CLIENT_DEBUG: '.length..-1]
              elsif line =~ /^CLIENT_INTERNAL_ERROR: /
                result.errorIO << line['CLIENT_INTERNAL_ERROR: '.length..-1]
              else
                result.errorIO << line['CLIENT_ERROR: '.length..-1]
                result.hasUserActionableError = true
              end
            elsif line =~ /^CART_DATA: /
              result.data << line['CART_DATA: '.length..-1]
            elsif line =~ /^CART_PROPERTIES: /
              property = line['CART_PROPERTIES: '.length..-1].chomp.split('=')
              result.cart_properties[property[0]] = property[1]
            elsif line =~ /^APP_INFO: /
              result.appInfoIO << line['APP_INFO: '.length..-1]
            elsif result.exitcode == 0
              if line =~ /^SSH_KEY_(ADD|REMOVE): /
                if line =~ /^SSH_KEY_ADD: /
                  key = line['SSH_KEY_ADD: '.length..-1].chomp
                  result.cart_commands.push({:command => "SYSTEM_SSH_KEY_ADD", :args => [key]})
                else
                  result.cart_commands.push({:command => "SYSTEM_SSH_KEY_REMOVE", :args => []})
                end
              elsif line =~ /^APP_SSH_KEY_(ADD|REMOVE): /
                if line =~ /^APP_SSH_KEY_ADD: /
                  response = line['APP_SSH_KEY_ADD: '.length..-1].chomp
                  cart,key = response.split(' ')
                  cart = cart.gsub(".", "-")
                  result.cart_commands.push({:command => "APP_SSH_KEY_ADD", :args => [cart, key]})
                else
                  cart = line['APP_SSH_KEY_REMOVE: '.length..-1].chomp
                  cart = cart.gsub(".", "-")
                  result.cart_commands.push({:command => "APP_SSH_KEY_REMOVE", :args => [cart]})
                end
              elsif line =~ /^APP_ENV_VAR_REMOVE: /
                key = line['APP_ENV_VAR_REMOVE: '.length..-1].chomp
                result.cart_commands.push({:command => "APP_ENV_VAR_REMOVE", :args => [key]})
              elsif line =~ /^ENV_VAR_(ADD|REMOVE): /
                if line =~ /^ENV_VAR_ADD: /
                  env_var = line['ENV_VAR_ADD: '.length..-1].chomp.split('=')
                  result.cart_commands.push({:command => "ENV_VAR_ADD", :args => [env_var[0], env_var[1]]})
                else
                  key = line['ENV_VAR_REMOVE: '.length..-1].chomp
                  result.cart_commands.push({:command => "ENV_VAR_REMOVE", :args => [key]})
                end
              elsif line =~ /^BROKER_AUTH_KEY_(ADD|REMOVE): /
                if line =~ /^BROKER_AUTH_KEY_ADD: /
                  result.cart_commands.push({:command => "BROKER_KEY_ADD", :args => []})
                else
                  result.cart_commands.push({:command => "BROKER_KEY_REMOVE", :args => []})
                end
              elsif line =~ /^ATTR: /
                attr = line['ATTR: '.length..-1].chomp.split('=')
                result.cart_commands.push({:command => "ATTR", :args => [attr[0], attr[1]]})
              else
                #result.debugIO << line
              end
            else # exitcode != 0
              result.debugIO << line
              Rails.logger.debug "DEBUG: server results: " + line
            end
          end
        end
        result
      end

      def self.execute_parallel_jobs_impl(handle)
=begin
        handle.each { |id, job_list|
          options = MCollectiveApplicationContainerProxy.rpc_options
          rpc_client = rpcclient('openshift', :options => options)
          begin
            mc_args = { id => job_list }
            mcoll_reply = rpc_client.custom_request('execute_parallel', mc_args, id, {'identity' => id})
            rpc_client.disconnect
            if mcoll_reply and mcoll_reply.length > 0
              mcoll_reply = mcoll_reply[0]
              output = mcoll_reply.results[:data][:output]
              exitcode = mcoll_reply.results[:data][:exitcode]
              Rails.logger.debug("DEBUG: Output of parallel execute: #{output}, status: #{exitcode}")
              handle[id] = output if exitcode == 0
            end
          ensure
            rpc_client.disconnect
          end
        }
=end
        if handle && !handle.empty?
          begin
            options = MCollectiveApplicationContainerProxy.rpc_options
            rpc_client = rpcclient('openshift', :options => options)
            mc_args = handle.clone
            identities = handle.keys
            rpc_client.custom_request('execute_parallel', mc_args, identities, {'identity' => identities}).each { |mcoll_reply|
              if mcoll_reply.results[:statuscode] == 0 
                output = mcoll_reply.results[:data][:output]
                exitcode = mcoll_reply.results[:data][:exitcode]
                sender = mcoll_reply.results[:sender]
                Rails.logger.debug("DEBUG: Output of parallel execute: #{output}, exitcode: #{exitcode}, from: #{sender}")
                output.each do |o|
                  r = MCollectiveApplicationContainerProxy.sanitize_result(o[:result_stdout], exitcode) if o.kind_of?(Hash) and o.include?(:result_stdout)
                  o[:result_stdout] = r.resultIO.string.chomp if r and (r.resultIO.string.chomp.length != 0)
                end if output.kind_of?(Array)
                handle[sender] = output if exitcode == 0
              end
            }
          ensure
            rpc_client.disconnect
          end
        end
      end
    end
end
