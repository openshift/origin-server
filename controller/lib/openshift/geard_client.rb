require 'mcollective'
require 'open-uri'
require 'timeout'
require 'httpclient'

include MCollective::RPC

#
# The OpenShift module is a namespace for all OpenShift related objects and
# methods.
#
module OpenShift

    # Implements the broker-node communications to the geard.  It also has a
    # set of just plain functions which live here because they relate
    # to broker/node communications.
    #
    class GeardClient < OpenShift::ApplicationContainerProxy
      include AsyncAware

      # A Node ID string
      attr_accessor :id

      # A District ID string
      attr_accessor :district

      # <<constructor>>
      #
      # Create an app descriptor/handle for remote controls
      #
      # INPUTS:
      # * id: string - a unique app identifier
      # * district: <type> - a classifier for app placement
      #
      def initialize(id, district=nil)
        @id = id
        #TODO hardcode to localhost for now, should be passed in ID
        @hostname = ENV["GEARD_HOST_PORT"] || "localhost:43273"
        @district = district
      end

      # <<factory method>>
      #
      # Find a node which fulfills app requirements.  Implements the superclass
      # find_all_available() method
      #
      # INPUTS:
      # * node_profile: string identifier for a set of node characteristics
      # * district_uuid: identifier for the district
      # * least_preferred_servers: list of server identities that are least preferred. These could be the ones that won't allow the gear group to be highly available
      # * gear_exists_in_district: true if the gear belongs to a node in the same district
      # * required_uid: the uid that is required to be available in the destination district
      #
      # RETURNS:
      # * a list of available nodes
      #
      # RAISES:
      # * OpenShift::NodeUnavailableException
      #
      # NOTES:
      # * a class method on Node?
      # * Uses Rails.configuration.msg_broker
      # * Uses District
      #
      # VALIDATIONS:
      # * If gear_exists_in_district is true, then required_uid cannot be set and has to be nil
      # * If gear_exists_in_district is true, then district_uuid must be passed and cannot be nil
      #
      def self.find_all_available_impl(opts=nil)
        #TODO
        return []
      end

      # <<factory method>>
      #
      # Find a single node. Implements superclass find_one() method.
      #
      # INPUTS:
      # * node_profile: characteristics for node filtering
      #
      # RETURNS:
      # * a list of server_info arrays
      def self.find_one_impl(node_profile=nil)
        #TODO
        return nil
      end

      # <<orphan>>
      # <<class method>>
      #
      # Return a list of blacklisted namespaces and app names.
      # Implements superclass get_blacklisted() method.
      #
      # INPUTS:
      # * none
      #
      # RETURNS:
      # * empty list
      #
      # NOTES:
      # * Is this really a function of the broker
      #
      def self.get_blacklisted_in_impl
        []
      end

      # <<class method>>
      #
      # <<query>>
      #
      # Query all nodes for all available cartridges
      #
      # INPUTS:
      # * none
      #
      # RETURNS:
      # * An array of OpenShift::Cartridge objects
      #
      def get_available_cartridges
        #TODO
        return nil
      end

      # <<object method>>
      #
      # <<attribute getter>>
      #
      # Request the disk quotas from a Gear on a node
      #
      # RETURNS:
      # * an array with following information:
      #
      # [Filesystem, blocks_used, blocks_soft_limit, blocks_hard_limit,
      # inodes_used, inodes_soft_limit, inodes_hard_limit]
      #
      # RAISES:
      # * OpenShift::NodeException
      #
      def get_quota(gear)
        #TODO
        return nil
      end

      # <<object method>>
      #
      # <<attribute setter>>
      #
      # Set blocks hard limit and inodes hard limit for uuid.
      # Effects disk quotas on Gear on Node
      #
      # INPUT:
      # * gear: A Gear object
      # * storage_in_gb: integer
      # * inodes: integer
      #
      # RETURNS
      # * Not sure, mcoll_result? a string?
      #
      # RAISES:
      # * OpenShift::NodeException
      #
      # NOTES:
      # * a pair of attribute setters on a Gear object
      #
      def set_quota(gear, storage_in_gb, inodes)
        #TODO
      end

      # Reserve a UID within a district or service
      #
      # UIDs must be unique in a district to allow migration without requiring
      # reassigning Username (Gear UUID) and Unix User UID on migrate
      # Perhaps a query on the nodes for "next UID"?
      #
      # INPUTS:
      # * district_uuid: String: District handle or identifier
      # * preferred_uid: Integer
      #
      # RAISES:
      # * OpenShift::OOException
      #
      # NOTES:
      # * a method on District class of the node.
      #
      def reserve_uid(district_uuid=nil, preferred_uid=nil)
        reserved_uid = nil
        if Rails.configuration.msg_broker[:districts][:enabled]
          if @district
            district_uuid = @district.uuid
          elsif !district_uuid
            if @id
              begin
                district = District.find_by({"servers.name" => @id})
                district_uuid = district.uuid
              rescue Mongoid::Errors::DocumentNotFound
                district_uuid = 'NONE'
              end
            else
              district_uuid = get_district_uuid
            end
          end
          if district_uuid && district_uuid != 'NONE'
            reserved_uid = District::reserve_uid(district_uuid, preferred_uid)
            raise OpenShift::OOException.new("uid could not be reserved in target district '#{district_uuid}'.  Please ensure the target district has available capacity or does not contain a conflicting uid.") unless reserved_uid
          end
        end
        reserved_uid
      end

      # Release a UID reservation within a District
      #
      # UIDs must be unique in a district to allow migration without requiring
      # reassigning Username (Gear UUID) and Unix User UID on migrate
      # Perhaps a query on the nodes for "next UID"?
      #
      # INPUTS:
      # * uid: Integer - the UID to unreserve within the district
      # * district_uuid: String - district handle or identifier
      #
      # NOTES:
      # * method on the District object.
      #
      def unreserve_uid(uid, district_uuid=nil)
        if Rails.configuration.msg_broker[:districts][:enabled]
          if @district
            district_uuid = @district.uuid
          elsif !district_uuid
            if @id
              begin
                district = District.find_by({"servers.name" => @id})
                district_uuid = district.uuid
              rescue Mongoid::Errors::DocumentNotFound
                district_uuid = 'NONE'
              end
            else
              district_uuid = get_district_uuid
            end
          end
          if district_uuid && district_uuid != 'NONE'
            #cleanup
            District::unreserve_uid(district_uuid, uid)
          end
        end
      end

      #
      # <<instance method>>
      #
      # Create a gear
      #
      # INPUTS:
      # * gear: a Gear object
      # * quota_blocks: Integer - max file space in blocks
      # * quota_files: Integer - max files count
      #
      # RETURNS:
      #  "result", stdout and exit code
      #
      def create(gear, quota_blocks=nil, quota_files=nil, sshkey_required=false, initial_deployment_dir_required=true)
        app = gear.application
        result = nil
        clnt = HTTPClient.new
        # TODO this assumes there is only one component_instance and is currently requiring looking up the CartridgeType
        image_name = gear.component_instances[0].cartridge.image

        if app.init_git_url
          # Go do the build
          # TODO temporarily just use the gear uuid as the image
          build_post_body = {
            "BaseImage" => image_name,
            "Source" => app.init_git_url,
            "Tag" => gear.uuid
          }
          res = clnt.post("#{build_base_geard_url}build-image", build_post_body.to_json, build_geard_post_headers)
          # Update the image_name we use for create to be whatever we pass to the build call as the Tag
          image_name = gear.uuid
        end

        # Hardcoded to request port 8080 be exposed inside the container
        post_body = {
          "Image" => image_name,
          "Started" => true,
          "Ports" => [
          ]
        }
        gear.component_instances[0].cartridge.endpoints.each do |endpoint|
          post_body["Ports"] << {"internal" => endpoint.private_port} if endpoint.private_port
        end
        res = clnt.put("#{build_base_geard_url}container/#{gear.uuid}", post_body.to_json, build_geard_post_headers)
        portmapping = res.header["X-Portmapping"]
        result = ResultIO.new
        result.resultIO << res.body
        #todo for now assume anything less than 400 is OK
        if res.status_code < 400
          result.resultIO << "The port mapping for this app is #{portmapping.join(', ').gsub('=',' -> ')}"
          #TODO store the port mapping onto the gear in mongo
        else
          #TODO error handling here
        end
        result
      end

      #
      # Remove a gear from a node
      # Optionally release a reserved UID from the District.
      #
      # INPUTS:
      # * gear: a Gear object
      # * keep_uid: boolean
      # * uid: Integer: reserved UID
      # * skip_hooks: boolean
      #
      # RETURNS:
      # * ResultIO
      #
      def destroy(gear, keep_uid=false, uid=nil, skip_hooks=false)
        #TODO WIP, needed to complete ssh key commands
        ResultIO.new
      end

      # Add an SSL certificate to a gear on the remote node and associate it with
      # a server name.
      #
      # INPUTS:
      # * gear: a Gear object
      # * priv_key: String - the private key value
      # * server_alias: String - the name of the server which will offer this key
      # * passphrase: String - the private key passphrase or '' if its unencrypted.
      #
      # RETURNS: ResultIO
      #
      def add_ssl_cert(gear, ssl_cert, priv_key, server_alias, passphrase='')
        #TODO
        return result_io
      end

      # remove an SSL certificate to a gear on the remote node.
      # See node/bin/oo-ssl-cert-remove
      #
      # INPUTS:
      # * gear: a Gear object
      # * server_alias: String - the name of the server which will offer this key
      #
      # RETURNS: ResultIO
      #
      def remove_ssl_cert(gear, server_alias)
        #TODO
        return result_io
      end

      # fetches all SSL certificates from a gear on the remote node.
      #
      # INPUTS:
      # * gear: a Gear object
      #
      # RETURNS: an array of arrays
      #  * each array consists of three elements
      #     - the SSL certificate
      #     - the private key
      #     - the alias
      #
      def get_all_ssl_certs(gear)
        #TODO
        return nil
      end

      #
      # Add an environment variable on gear on a remote node.
      # Calls oo-env-var-add on the remote node
      #
      # INPUTS:
      # * gear: a Gear object
      # * key: String - environment variable name
      # * value: String - environment variable value
      #
      # RETURNS:
      # * ResultIO
      #
      #
      def add_env_var(gear, key, value)
        #TODO
        return result_io
      end

      #
      # Remove an environment variable on gear on a remote node
      #
      # INPUTS:
      # * gear: a Gear object
      # * key: String - environment variable name
      #
      # RETURNS:
      # * ResultIO
      #
      def remove_env_var(gear, key)
        #TODO
        return result_io
      end

      #
      # Add a broker auth key.  The broker auth key allows an application
      # to request scaling and other actions from the broker.
      #
      # INPUTS:
      # * gear: a Gear object
      # * iv: String - SSL initialization vector
      # * token: String - a broker auth key
      #
      # RETURNS:
      # * ResultIO
      #
      def add_broker_auth_key(gear, iv, token)
        #TODO
        return result_io
      end

      #
      # Remove a broker auth key. The broker auth key allows an application
      # to request scaling and other actions from the broker.
      #
      # INPUTS:
      # * gear: a Gear object
      #
      # RETURNS:
      # * ResultIO
      #
      def remove_broker_auth_key(gear)
        #TODO
        return result_io
      end


      #
      # Get the operating state of a gear
      #
      # INPUTS:
      # * gear: Gear Object
      #
      # RETURNS:
      # * ResultIO
      #
      def show_state(gear)
        #TODO
        return result_io
      end

      # <<accessor>>
      # Get the public hostname of a Node
      #
      # INPUTS:
      # none
      #
      # RETURNS:
      # * String: the public hostname of a node
      #
      def get_public_hostname
        #TODO
        return nil
      end

      # <<accessor>>
      # Get the "capacity" of a node
      #
      # INPUTS:
      # none
      #
      # RETURNS:
      # * Float: the "capacity" of a node
      #
      def get_capacity
        #TODO
        return nil
      end

      # <<accessor>>
      # Get the "active capacity" of a node
      #
      # INPUTS:
      # none
      #
      # RETURNS:
      # * Float: the "active capacity" of a node
      #
      def get_active_capacity
        #TODO
        return nil
      end

      # <<accessor>>
      # Get the district UUID (membership handle) of a node
      #
      # INPUTS:
      # none
      #
      # RETURNS:
      # * String: the UUID of a node's district
      #
      def get_district_uuid
        #TODO
        return nil
      end

      # <<accessor>>
      # Get the public IP address of a Node
      #
      # INPUTS:
      # none
      #
      # RETURNS:
      # * String: the public IP address of a node
      #
      def get_ip_address
        #TODO
        return nil
      end

      # <<accessor>>
      # Get the public IP address of a Node
      #
      # INPUTS:
      # none
      #
      # RETURNS:
      # * String: the public IP address of a node
      #
      def get_public_ip_address
        #TODO
        return nil
      end

      # <<accessor>>
      # Get the "node profile" of a Node
      #
      # INPUTS:
      # none
      #
      # RETURNS:
      # * String: the "node profile" of a node
      #
      def get_node_profile
        #TODO
        return nil
      end

      # <<accessor>>
      # Get the quota blocks of a Node
      #
      # Is this disk available or the default quota limit?
      # It's from Facter.
      #
      # INPUTS:
      # none
      #
      # RETURNS:
      # * Integer: the "quota blocks" of a node
      #
      def get_quota_blocks
        #TODO
        return nil
      end

      # <<accessor>>
      # Get the quota files of a Node
      #
      # Is this disk available or the default quota limit?
      # It's from Facter.
      #
      # INPUTS:
      # none
      #
      # RETURNS:
      # * Integer: the "quota files" of a node
      #
      def get_quota_files
        #TODO
        return nil
      end

      #
      # Deploy a gear.
      #
      # INPUTS:
      # * gear: a Gear object
      # * hot_deploy: indicates whether this is a hot deploy
      # * force_clean_build: indicates whether this should be a clean build
      # * ref: the ref to deploy
      # * artifact_url: the url of the artifacts to deploy
      #
      # RETURNS
      # ResultIO: the result of running post-configure on the cartridge
      #
      def deploy(gear, hot_deploy=false, force_clean_build=false, ref=nil, artifact_url=nil)
        #TODO
        return result_io
      end

      #
      # Activate a deployment for a gear
      #
      # INPUTS:
      # * gear: a Gear object
      # * deployment_id: a deployment id
      #
      # RETURNS:
      # * ResultIO
      #
      def activate(gear, deployment_id)
        #TODO
        return result_io
      end


      #
      # Start cartridge services within a gear
      #
      # INPUTS:
      # * gear: a Gear object
      # * cart: a Cartridge object
      #
      # RETURNS:
      # * ResultIO
      #
      def start(gear, component)
        #TODO
        return result_io
      end

      def get_start_job(gear, component)
        #TODO
        args = build_base_gear_args gear
        args[:method] = :put
        RemoteJob.new('openshift-origin-node', "container/#{gear.uuid}/started", args)
      end

      #
      # Stop cartridge services within a gear
      #
      # INPUTS:
      # * gear: a Gear object
      # * cart: a Cartridge object
      #
      # RETURNS:
      # * ResultIO
      #
      def stop(gear, component)
        #TODO
        return result_io
      end

      def get_stop_job(gear, component)
        #TODO
        args = build_base_gear_args gear
        args[:method] = :put
        RemoteJob.new('openshift-origin-node', "container/#{gear.uuid}/stopped", args)
      end

      #
      # Force gear services to stop
      #
      # INPUTS:
      # * gear: Gear object
      # * cart: Cartridge object
      #
      # RETURNS:
      # * ResultIO
      #
      def force_stop(gear, cart)
        #TODO
        return result_io
      end

      def get_force_stop_job(gear, component)
        #TODO
        args = build_base_gear_args gear
        RemoteJob.new('openshift-origin-node', "container/#{gear.uuid}/stopped", args)
      end

      #
      # Stop and restart cart services on a gear
      #
      # INPUTS:
      # * gear: a Gear object
      # * cart: a Cartridge object
      #
      # RETURNS:
      # * a ResultIO of undefined content
      #
      def restart(gear, component)
        #TODO
        return result_io
      end

      def get_restart_job(gear, component, all=false)
        args = build_base_gear_args gear
        args[:method] = :post
        RemoteJob.new('openshift-origin-node', "container/#{gear.uuid}/restart", args)
      end

      #
      # Get the status from cart services in an existing Gear
      #
      # INPUTS:
      # * gear: a Gear object
      # * cart: a Cartridge object
      #
      # RETURNS:
      # * A ResultIO object of undetermined content
      #
      def status(gear, component)
        #TODO
        return result_io
      end

      #
      # Clean up unneeded artifacts in a gear
      #
      # INPUTS:
      # * gear: a Gear object
      #
      # RETURNS:
      # * String: stdout from a command
      #
      def tidy(gear)
        #TODO
        return result_io
      end

      def get_tidy_job(gear)
        #TODO
        RemoteJob.new('openshift-origin-node', 'tidy', args)
      end

      #
      # dump the cartridge threads
      #
      # INPUTS:
      # * gear: a Gear object
      # * cart: a Cartridge object
      #
      # RETURNS:
      # * a ResultIO of undetermined content
      #
      def threaddump(gear, component)
        #TODO
        return result_io
      end

      def get_threaddump_job(gear, component)
        #TODO
        RemoteJob.new('openshift-origin-node', 'threaddump', args)
      end

      #
      # expose a TCP port
      #
      # INPUTS:
      # * gear: a Gear object
      # * cart: a Cartridge object
      #
      # RETURNS:
      # * a ResultIO of undetermined content
      #
      def get_expose_port_job(gear, component)
        #TODO
        RemoteJob.new('openshift-origin-node', 'expose-port', args)
      end

      def get_conceal_port_job(gear, component)
        #TODO
        RemoteJob.new('openshift-origin-node', 'conceal-port', args)
      end

      def get_show_port_job(gear, component)
        #TODO
        RemoteJob.new('openshift-origin-node', 'show-port', args)
      end

      def expose_port(gear, component)
        #TODO
        parse_result(result)
      end

      #
      # get information on a TCP port
      #
      # INPUTS:
      # * gear: a Gear object
      # * cart: a Cartridge object
      #
      # RETURNS:
      # * a ResultIO of undetermined content
      #
      # Deprecated: remove from the REST API and then delete this.
      def show_port(gear, cart)
        ResultIO.new
      end

      #
      # Add an application alias to a gear
      #
      # INPUTS:
      # * gear: a Gear object
      # * server_alias: String - a new FQDN for the gear
      #
      # RETURNS:
      # * String: stdout from a command
      #
      def add_alias(gear, server_alias)
        #TODO
        return result_io
      end

      #
      # remove an application alias to a gear
      #
      # INPUTS:
      # * gear: a Gear object
      # * server_alias: String - a new FQDN for the gear
      #
      # RETURNS:
      # * String: stdout from a command
      #
      def remove_alias(gear, server_alias)
        #TODO
        return result_io
      end

      #
      # Add multiple application aliases to a gear
      #
      # INPUTS:
      # * gear: a Gear object
      # * server_aliases: Array - a list of FQDN for the gear
      #
      # RETURNS:
      # * String: stdout from a command
      #
      def add_aliases(gear, server_aliases)
        #TODO
        return result_io
      end

      #
      # remove multiple application aliases from a gear
      #
      # INPUTS:
      # * gear: a Gear object
      # * server_aliases: Array - a list of FQDN for the gear
      #
      # RETURNS:
      # * String: stdout from a command
      #
      def remove_aliases(gear, server_aliases)
        #TODO
        return result_io
      end

      #
      # Add or Update user environment variables to all gears in the app
      #
      # INPUTS:
      # * gear: a Gear object
      # * env_vars: Array of environment variables, e.g.:[{'name'=>'FOO','value'=>'123'}, {'name'=>'BAR','value'=>'abc'}]
      # * gears_ssh_endpoint: list of ssh gear endpoints
      #
      # RETURNS:
      # * String: stdout from a command
      #
      def set_user_env_vars(gear, env_vars, gears_ssh_endpoint)
        #TODO
        return result_io
      end

      #
      # Remove user environment variables from all gears in the app
      #
      # INPUTS:
      # * gear: a Gear object
      # * env_vars: Array of environment variable names, e.g.:[{'name'=>'FOO'}, {'name'=>'BAR'}]
      # * gears_ssh_endpoint: list of ssh gear endpoints
      #
      # RETURNS:
      # * String: stdout from a command
      #
      def unset_user_env_vars(gear, env_vars, gears_ssh_endpoint)
        #TODO
        return result_io
      end

      #
      # List all or selected  user environment variables for the app
      #
      # INPUTS:
      # * gear: a Gear object
      # * env_var_names: List of environment variable names, e.g.:['FOO', 'BAR']
      #
      # RETURNS:
      # * String: stdout from a command
      #
      def list_user_env_vars(gear, env_var_names)
        #TODO
        return result_io
      end

      #
      # Re-establishes the frontend httpd server's configuration for all cartridges on a gear.
      #
      # INPUTS:
      # * gear: a Gear object
      # * proxy_only : flag to suggest only re-establishing proxy cartridge's connections
      #
      # RETURNS:
      # * Endpoint data
      #
      def frontend_reconnect(gear, proxy_only=false)
        #TODO
        return result_io
      end

      #
      # Extracts the frontend httpd server configuration from a gear.
      #
      # INPUTS:
      # * gear: a Gear object
      #
      # RETURNS:
      # * String - backup blob from the front-end server
      #
      #
      def frontend_backup(gear)
        #TODO
        return nil
      end

      #
      # Transmits the frontend httpd server configuration to a gear.
      #
      # INPUTS:
      # * backup: string which was previously returned by frontend_backup
      #
      # RETURNS:
      # * String - "parsed result" of an MCollective reply
      #
      #
      def frontend_restore(backup)
        #TODO
        return result_io
      end

      #
      # Get status on an add env var job?
      #
      # INPUTS:
      # * gear: a Gear object
      # * key: an environment variable name
      # * value: and environment variable value
      #
      # RETURNS:
      # * a RemoteJob object
      #
      # NOTES:
      # * uses RemoteJob
      #
      def get_env_var_add_job(gear, key, value)
        #TODO
        job = RemoteJob.new('openshift-origin-node', 'env-var-add', args)
        job
      end

      #
      # Create a job to remove an environment variable
      #
      # INPUTS:
      # * gear: a Gear object
      # * key: an environment variable name
      #
      # RETURNS:
      # * a RemoteJob object
      #
      # NOTES:
      # * uses RemoteJob
      #
      def get_env_var_remove_job(gear, key)
        #TODO
        job = RemoteJob.new('openshift-origin-node', 'env-var-remove', args)
        job
      end

      #
      # Create a job to add authorized keys
      #
      # INPUTS:
      # * gear: a Gear object
      # * ssh_keys: Array - SSH public keys
      #
      # RETURNS:
      # * a RemoteJob object
      #
      # NOTES:
      # * uses RemoteJob
      #
      def get_add_authorized_ssh_keys_job(gear, ssh_keys)
        #WIP
        args = build_base_gear_args(gear)
        containers = [ {'Id' => gear.uuid} ]
        args[:method] = :put        
        args[:body] = {'Keys' => build_ssh_key_args_with_content(ssh_keys), 'Containers' => containers }
        RemoteJob.new('openshift-origin-node', 'keys', args)
      end

      #
      # Create a job to update gear configuration
      #
      # INPUTS:
      # * gear: a Gear object
      # * config: a Hash of config to update
      #
      # RETURNS:
      # * a RemoteJob object
      #
      # NOTES:
      # * uses RemoteJob
      #
      def get_update_configuration_job(gear, config)
        #TODO
        job = RemoteJob.new('openshift-origin-node', 'update-configuration', args)
        job
      end

      #
      # Create a job to remove authorized keys.
      #
      # INPUTS:
      # * gear: a Gear object
      # * ssh_keys: Array - SSH public keys
      #
      # RETURNS:
      # * a RemoteJob object
      #
      # NOTES:
      # * uses RemoteJob
      def get_remove_authorized_ssh_keys_job(gear, ssh_keys)
        #TODO
        job = RemoteJob.new('openshift-origin-node', 'authorized-ssh-key-batch-remove', args)
        job
      end

      #
      # Create a job to remove existing authorized ssh keys and add the provided ones to the gear
      #
      # INPUTS:
      # * gear: a Gear object
      # * ssh_keys: Array - SSH public key list
      #
      # RETURNS:
      # * a RemoteJob object
      #
      # NOTES:
      # * uses RemoteJob
      #
      def get_fix_authorized_ssh_keys_job(gear, ssh_keys)
        #TODO
        job = RemoteJob.new('openshift-origin-node', 'authorized-ssh-keys-replace', args)
        job
      end

      #
      # Create a job to add a broker auth key
      #
      # INPUTS:
      # * gear: a Gear object
      # * iv: String - Broker auth initialization vector
      # * token: String - Broker auth token
      #
      # RETURNS:
      # * a RemoteJob object
      #
      # NOTES:
      # * uses RemoteJob
      #
      def get_broker_auth_key_add_job(gear, iv, token)
        #TODO
        job = RemoteJob.new('openshift-origin-node', 'broker-auth-key-add', args)
        job
      end

      #
      # Create a job to execute a connector hook ??
      #
      # INPUTS:
      # * gear: a Gear object
      # * cart: a Cartridge object
      # * connector_name: String
      # * input_args: Array of String
      #
      # RETURNS:
      # * a RemoteJob object
      #
      # NOTES:
      # * uses RemoteJob
      #
      def get_execute_connector_job(gear, component, connector_name, connection_type, input_args, pub_cart=nil)
        #TODO
        job = RemoteJob.new('openshift-origin-node', 'connector-execute', args)
        job
      end

      #
      # Create a job to unsubscribe
      #
      # INPUTS:
      # * gear: a Gear object
      # * cart: a Cartridge object
      # * publish_cart_name: a Cartridge object
      #
      # RETURNS:
      # * a RemoteJob object
      #
      # NOTES:
      # * uses RemoteJob
      #
      def get_unsubscribe_job(gear, component, publish_cart_name)
        #TODO
        job = RemoteJob.new('openshift-origin-node', 'unsubscribe', args)
        job
      end

      #
      # Create a job to return the state of a gear
      #
      # INPUTS:
      # * gear: a Gear object
      #
      # RETURNS:
      # * a RemoteJob object
      #
      # NOTES:
      # * uses RemoteJob
      #
      def get_show_state_job(gear)
        #TODO
        job = RemoteJob.new('openshift-origin-node', 'app-state-show', args)
        job
      end


      #
      # Create a job to get status of an application
      #
      # INPUTS:
      # * gear: a Gear object
      # * cart: a Cartridge object
      #
      # RETURNS:
      # * a RemoteJob object
      #
      # NOTES:
      # * uses RemoteJob
      #
      def get_status_job(gear, component)
        #TODO
        job = RemoteJob.new(component.cartridge_name, 'status', args)
        job
      end

      #
      # Create a job to check the disk quota on a gear
      #
      # INPUTS:
      # * gear: a Gear object
      #
      # RETURNS:
      # * a RemoteJob object
      #
      # NOTES:
      # * uses RemoteJob
      #
      def get_show_gear_quota_job(gear)
        #TODO
        job = RemoteJob.new('openshift-origin-node', 'get-quota', args)
        job
      end

      #
      # Create a job to change the disk quotas on a gear
      #
      # INPUTS:
      # * gear: a Gear object
      #
      # RETURNS:
      # * a RemoteJob object
      #
      # NOTES:
      # * uses RemoteJob
      #
      def get_update_gear_quota_job(gear, storage_in_gb, inodes)
        #TODO
        job = RemoteJob.new('openshift-origin-node', 'set-quota', args)
        job
      end

      # Enable/disable a target gear in the proxy component
      def get_update_proxy_status_job(gear, options)
        #TODO
        RemoteJob.new(@@C_CONTROLLER, 'update-proxy-status', args)
      end

      #
      # get the status of an application
      #
      # INPUT:
      # app: an Application object
      #
      # RETURN:
      # * Array: [idle, leave_stopped]
      #
      # NOTES:
      # * calls get_cart_status
      # * method on app or gear?
      # * just a shortcut?
      #
      def get_app_status(app)
        instance = app.web_component_instance || app.component_instances.first
        gear = instance.gears.first
        idle, leave_stopped, _, _ = get_cart_status(gear, instance)
        return idle, leave_stopped
      end

      #
      # get the status of a cartridge in a gear?
      #
      # INPUTS:
      # * gear: a Gear object
      # * cart_name: String
      #
      # RETURNS:
      # * Array: [idle, leave_stopped, quota_file, quota_blocks]
      #
      # NOTES:
      # * uses do_with_retry
      #
      def get_cart_status(gear, component)
        app = gear.application
        source_container = gear.get_proxy
        leave_stopped = false
        idle = false
        quota_blocks = nil
        quota_files = nil
        log_debug "DEBUG: Getting existing app '#{app.name}' status before moving"
        do_with_retry('status') do
          result = source_container.status(gear, component)
          result.properties["attributes"][gear.uuid].each do |key, value|
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
        end

        cart_name = component.cartridge_name
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
      # get details about instance's node
      #
      # RETURN:
      # * Map: name => values for one node
      #
      def get_node_details(name_list)
        #TODO
        return nil
      end

      #
      # get details (in MCollective, facts) about all nodes that respond
      #
      # RETURN:
      # * Hash of hashes: node identity => fact map for each node
      #
      def self.get_details_for_all_impl(name_list)
        #TODO
        return nil
      end

      #
      # Set the district of a node
      #
      # INPUTS:
      # * uuid: String
      # * active: String (?)
      # * first_uid: Integer
      # * max_uid: Integer
      #
      # RETURNS:
      # * ResultIO
      #
      def set_district(uuid, active, first_uid, max_uid)
        #TODO
        return nil
      end

      #
      # Set the district uid limits for all district nodes
      #
      # INPUTS:
      # * uuid: String
      # * first_uid: Integer
      # * max_uid: Integer
      #
      # RETURNS:
      # * ResultIO?
      #
      # NOTES:
      # * uses MCollective::RPC::Client
      #
      def self.set_district_uid_limits_impl(uuid, first_uid, max_uid)
        #TODO
        return nil
      end

      # Returns a hash of env variables for a given gear uuid
      #
      # INPUTS:
      # * gear_uuid: String
      #
      # RETURNS:
      # * Hash
      #
      def get_gear_envs(gear_uuid)
        #TODO
        return nil
      end

      protected

      #
      # Try some action until it passes or exceeds a maximum number of tries
      #
      # INPUTS:
      # * action: Block: a code block or method with no arguments
      # * num_tries: Integer
      #
      # RETURNS:
      # * unknown: the result of the action
      #
      # RAISES:
      # * Exception
      #
      # CATCHES:
      # * Exception
      #
      # NOTES:
      # * uses log_debug
      # * just loops retrys
      #
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

      #
      # Start a component service
      #
      # INPUTS:
      # * gear: a Gear object
      # * component: String: a component name
      #
      # RETURNS:
      # * ResultIO
      #
      def start_component(gear, component)
        #TODO
        return result_io
      end

      #
      # Stop a component service
      #
      # INPUTS:
      # * gear: a Gear object
      # * component: String: a component name
      #
      # RETURNS:
      # * ResultIO
      #
      def stop_component(gear, component)
        #TODO
        return result_io
      end

      #
      # Restart a component service
      #
      # INPUTS:
      # * gear: a Gear object
      # * component: String: a component name
      #
      # RETURNS:
      # * ResultIO
      #
      def restart_component(gear, component)
        #TODO
        return result_io
      end

      #
      # Get the status a component service
      #
      # INPUTS:
      # * gear: a Gear object
      # * component: String: a component name
      #
      # RETURNS:
      # * ResultIO
      #
      def component_status(gear, component)
        #TODO
        return result_io
      end

      #
      # Wrap the log messages so it doesn't HAVE to be rails
      #
      # INPUTS:
      # * message: String
      #
      def log_debug(message)
        Rails.logger.debug message
        puts message
      end

      #
      # Wrap the log messages so it doesn't HAVE to be rails
      #
      # INPUTS:
      # * message: String
      #
      def log_error(message)
        Rails.logger.error message
        puts message
      end

      #
      # Returns the server identity of the specified gear
      #
      # INPUTS:
      # * gear_uuid: String
      #
      # RETURNS:
      # * server identity (string)
      #
      # NOTES:
      # * uses rpc_exec
      # * loops over all nodes
      #
      def self.find_gear(gear_uuid, servers = nil)
        #TODO
        server_identity = nil
        return server_identity
      end

      #
      # Returns whether this server has the specified app
      #
      # INPUTS:
      # * app_uuid: String
      # * app_name: String
      #
      # RETURNS:
      # * Boolean
      #
      def has_gear?(gear_uuid)
        #TODO
        return true
      end

      #
      # Returns whether this server has the specified embedded app
      #
      # INPUTS:
      # * app_uuid: String
      # * embedded_type: String
      #
      # RETURNS:
      # * Boolean
      #
      def has_embedded_app?(app_uuid, embedded_type)
        #TODO
        return true
      end

      #
      # Returns whether this server has already reserved the specified uid as a uid or gid
      #
      # INPUTS:
      # * uid: Integer
      #
      # RETURNS:
      # * Boolean
      #
      def has_uid_or_gid?(uid)
        #TODO
        return true
      end

      #
      # Returns whether this gear has the specified cartridge
      #
      # INPUTS:
      # * gear_uuid: String
      # * cartridge: String
      #
      # RETURNS:
      # * Boolean
      #
      def has_app_cartridge?(app_uuid, gear_uuid, cart)
        #TODO
        return true
      end

      #
      # Retrieve all gear IDs from all nodes (implementation)
      #
      # INPUTS:
      # * none
      #
      # RETURNS:
      # * Hash [gear_map[], node_map[]]
      #
      def self.get_all_gears_impl(opts)
        #TODO
        return [gear_map, sender_map]
      end

      def self.get_all_gears_endpoints_impl(opts)
        gear_map = {}
        #TODO
        return gear_map
      end

      #
      # Retrieve all active gears (implementation)
      #
      # INPUTS:
      # * none
      #
      # RETURNS:
      # * Hash: active_gears_map[nodekey]
      #
      def self.get_all_active_gears_impl
        active_gears_map = {}
        #TODO
        active_gears_map
      end

      #
      # Retrieve all ssh keys for all gears from all nodes (implementation)
      #
      # INPUTS:
      # * none
      #
      # RETURNS:
      # * Hash [gear_sshey_map[], node_list[]]
      #
      def self.get_all_gears_sshkeys_impl
        gear_sshkey_map = {}
        #TODO
        return [gear_sshkey_map, sender_list]
      end

      #
      # <<implementation>>
      # <<class method>>
      #
      # Execute a set of operations on a node in parallel
      #
      # INPUTS:
      # * handle: Hash ???
      #
      # RETURNS:
      # * ???
      #
      def self.execute_parallel_jobs_impl(handle)
        #TODO for now only handling a single geard host
        #TODO make this async, requires geardclient be an object instead of calling
        #   class methods
        handle.delete :args
        handle.keys.each do |identity|
          handle[identity].each do |parallel_job|
            job = parallel_job[:job]
            #async do
              clnt = HTTPClient.new
              # WIP job
              geard_op = job[:args]            
              http_method = geard_op[:method]
              http_body = geard_op[:body]
              geard_url = "#{build_base_geard_url (ENV['GEARD_HOST_PORT'] || 'localhost:8080')}#{job[:action]}"
              res = case http_method
                when :put 
                  if http_body.empty?
                    clnt.put(geard_url)
                  else
                    clnt.put(geard_url, http_body.to_json, build_geard_post_headers)
                  end
                when :delete 
                  clnt.delete(geard_url)
                when :get 
                  clnt.get(geard_url)
                when :post 
                  if http_body.empty?
                    clnt.post(geard_url)
                  else
                    clnt.post(geard_url, http_body.to_json, build_geard_post_headers)
                  end
                end
              handle[identity].each { |gear_info|
                gear_info[:result_stdout] = "(Gear Id: #{gear_info[:gear]}) #{res.body}"
                gear_info[:result_exit_code] = res.status_code < 400 ? 0 : res.status_code
              }
            #end
          end
        end
        #join!(240)
      end

      private

      def mask_user_creds(str)
        str.gsub(/(User: |Password: |username=|password=).*/, '\1[HIDDEN]')
      end

      def build_ssh_key_args_with_content(ssh_keys)
        #ssh_keys.map { |k| {'key' => k['content'], 'type' => k['type'], 'comment' => k['name'], 'content' => k['content']} }
        ssh_keys.map { |k| {'Type' => 'authorized_keys', 'Value' => "#{k['type']} #{k['content']}" } }
      end

      def build_ssh_key_args(ssh_keys)
        ssh_keys.map { |k| {'key' => k['content'], 'type' => k['type'], 'comment' => k['name']} }
      end

      def build_base_geard_url
        "http://#{@hostname}/"
      end

      def build_geard_post_headers
        {"Content-Type" => "application/json"}
      end

      def self.build_base_geard_url(hostname)
        "http://#{hostname}/"
      end

      #
      # Build base hash with arguments used to interact with geard
      #
      #
      def build_base_gear_args(gear, quota_blocks=nil, quota_files=nil, sshkey_required=false)
        app = gear.application
        { :method => :get, :body => {} }
      end

      def self.build_geard_post_headers
        {"Content-Type" => "application/json"}
      end

    end
end
