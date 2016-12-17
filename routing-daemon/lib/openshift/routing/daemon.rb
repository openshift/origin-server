require 'rubygems'
require 'logger'
require 'parseconfig'
require 'stomp'
require 'timeout'
require 'yaml'

module OpenShift

  # == Load Balancer Configuration Daemon
  #
  # Represents a daemon that listens for routing updates on ActiveMQ and
  # configures a remote routing in accordance with those updates.
  # The remote load balancer is represented by an
  # OpenShift::LoadBalancerModel object and controlled using an
  # OpenShift::LoadBalancerController object.
  #
  class RoutingDaemon
    def read_config cfgfile
      @cfg = ParseConfig.new(cfgfile)
      @logfile = @cfg['LOGFILE'] || '/var/log/openshift/routing-daemon.log'
      @loglevel = @cfg['LOGLEVEL'] || 'debug'
      @logger = Logger.new @logfile
      @logger.level = case @loglevel
                      when 'debug'
                        Logger::DEBUG
                      when 'info'
                        Logger::INFO
                      when 'warn'
                        Logger::WARN
                      when 'error'
                        Logger::ERROR
                      when 'fatal'
                        Logger::FATAL
                      else
                        raise StandardError.new "Invalid LOGLEVEL value: #{@loglevel}"
                      end
      @ha_dns_prefix = @cfg['HA_DNS_PREFIX'] || 'ha-'
      @user = @cfg['ACTIVEMQ_USER'] || 'routinginfo'
      @password = @cfg['ACTIVEMQ_PASSWORD'] || 'routinginfopasswd'
      @port = (@cfg['ACTIVEMQ_PORT'] || 61613).to_i
      @hosts = (@cfg['ACTIVEMQ_HOST'] || 'activemq.example.com').split(',').map do |hp|
        chunks = hp.split(":")
        h = chunks[0]
        p = chunks.size > 1 ? chunks[1] : @port
          {
            :host => h,
            # Originally, ACTIVEMQ_HOST allowed specifying only one host, with
            # the port specified separately in ACTIVEMQ_PORT.
            :port => p
      }
      end
      @plugin_prefix = "plugin.activemq.pool."
      pools = @cfg["#{@plugin_prefix}size"]
      unless pools.nil?
        pools = pools.to_i
        @logger.debug("#{@plugin_prefix}size=#{pools} setting was found, ACTIVEMQ_HOST settings will now be overridden by plugin.activemq.pool* settings")
        @hosts = []

        1.upto(pools) do |poolnum|
          host = {}

          host[:host] = @cfg["#{@plugin_prefix}#{poolnum}.host"]
          @logger.error("#{@plugin_prefix}#{poolnum}.host setting in #{cfgfile} is missing.") if host[:host].nil?
          host[:port] = @cfg["#{@plugin_prefix}#{poolnum}.port"].to_i
          @logger.error("#{@plugin_prefix}#{poolnum}.port setting in #{cfgfile} is missing.") if host[:port].nil?
          host[:ssl] = @cfg["#{@plugin_prefix}#{poolnum}.ssl"].to_s == "true"
          ssl_fallback = @cfg["#{@plugin_prefix}#{poolnum}.ssl.fallback"].to_s == "true"
          host[:ssl] = ssl_parameters(poolnum, ssl_fallback) if host[:ssl]

          @logger.debug("Adding #{host[:host]}:#{host[:port]} to the connection pool")
          @hosts << host
        end
      end

      @hosts = @hosts.map {|host| host.merge({ :login => @user, :passcode => @password })}
      @destination = @cfg['ACTIVEMQ_DESTINATION'] || @cfg['ACTIVEMQ_TOPIC'] || '/topic/routinginfo'
      @endpoint_types = (@cfg['ENDPOINT_TYPES'] || 'load_balancer').split(',')
      @cloud_domain = (@cfg['CLOUD_DOMAIN'] || 'example.com')
      @pool_name_format = @cfg['POOL_NAME'] || 'pool_ose_%a_%n_80'
      @monitor_name_format = @cfg['MONITOR_NAME']
      @monitor_path_format = @cfg['MONITOR_PATH']
      @monitor_up_code = @cfg['MONITOR_UP_CODE'] || '1'
      @monitor_type = @cfg['MONITOR_TYPE'] || 'http-ecv'
      @monitor_interval = @cfg['MONITOR_INTERVAL'] || '10'
      @monitor_timeout = @cfg['MONITOR_TIMEOUT'] || '5'
      @update_interval = (@cfg['UPDATE_INTERVAL'] || 5).to_i

      # @lb_model and instances thereof should not be used except to
      # pass an instance of @lb_model_class to an instance of
      # @lb_controller_class.
      case @cfg['LOAD_BALANCER'].downcase
      when 'nginx'
        require 'openshift/routing/controllers/simple'
        require 'openshift/routing/models/nginx'

        @lb_model_class = OpenShift::NginxLoadBalancerModel
        @lb_controller_class = OpenShift::SimpleLoadBalancerController
      when 'f5'
        require 'openshift/routing/controllers/simple'
        require 'openshift/routing/models/f5-icontrol-rest'

        @lb_model_class = OpenShift::F5IControlRestLoadBalancerModel
        @lb_controller_class = OpenShift::SimpleLoadBalancerController
      when 'f5_batched'
        require 'openshift/routing/controllers/batched'
        require 'openshift/routing/models/f5-icontrol-rest'

        @lb_model_class = OpenShift::F5IControlRestLoadBalancerModel
        @lb_controller_class = OpenShift::BatchedLoadBalancerController
      when 'lbaas'
        require 'openshift/routing/models/lbaas'
        require 'openshift/routing/controllers/asynchronous'

        @lb_model_class = OpenShift::LBaaSLoadBalancerModel
        @lb_controller_class = OpenShift::AsyncLoadBalancerController
      when 'dummy'
        require 'openshift/routing/models/dummy'
        require 'openshift/routing/controllers/simple'

        @lb_model_class = OpenShift::DummyLoadBalancerModel
        @lb_controller_class = OpenShift::SimpleLoadBalancerController
      when 'dummy_async'
        require 'openshift/routing/models/dummy'
        require 'openshift/routing/controllers/asynchronous'

        @lb_model_class = OpenShift::DummyLoadBalancerModel
        @lb_controller_class = OpenShift::AsyncLoadBalancerController
      else
        raise StandardError.new 'No routing-daemon.configured.'
      end
    end

    def ssl_parameters(poolnum, fallback)
        params = {:cert_file =>  @cfg["#{@plugin_prefix}#{poolnum}.ssl.cert"],
                  :key_file => @cfg["#{@plugin_prefix}#{poolnum}.ssl.key"],
                  :ts_files  => @cfg["#{@plugin_prefix}#{poolnum}.ssl.ca"]}

        raise "cert, key and ca has to be supplied for verified SSL mode" unless params[:cert_file] && params[:key_file] && params[:ts_files]

        raise "Cannot find certificate file #{params[:cert_file]}" unless File.exist?(params[:cert_file])
        raise "Cannot find key file #{params[:key_file]}" unless File.exist?(params[:key_file])

        params[:ts_files].split(",").each do |ca|
          raise "Cannot find CA file #{ca}" unless File.exist?(ca)
        end

        begin
          Stomp::SSLParams.new(params)
        rescue NameError
          raise "Stomp gem >= 1.2.2 is needed"
        end

        rescue Exception => e
        if fallback
          @logger.warn("Failed to set full SSL verified mode, falling back to unverified: #{e.class}: #{e}")
          return true
        else
          @logger.error("Failed to set full SSL verified mode: #{e.class}: #{e}")
          raise(e)
        end
    end

    def initialize cfgfile='/etc/openshift/routing-daemon.conf'
      read_config cfgfile

      @logger.info "Initializing routing controller..."
      @lb_controller = @lb_controller_class.new @lb_model_class, @logger, cfgfile
      @logger.info "Found #{@lb_controller.pools.length} pools:\n" +
                   @lb_controller.pools.map{|k,v|"  #{k} (#{v.members.length} members)"}.join("\n")

      client_id = Socket.gethostname + '-' + $$.to_s
      client_hdrs = {
        # We need STOMP 1.1 to be able to nack, and STOMP 1.1 needs the
        # client-id and host headers.
        "accept-version" => "1.1",
        "client-id" => client_id,
        "client_id" => client_id,
        "clientID" => client_id,
        "host" => "localhost" # Does not need to be the actual hostname.
      }

      @client_hash = {
        :hosts => @hosts,
        :reliable => true,
        :connect_headers => client_hdrs
      }
      connect
    end

    def connect
      @logger.info "Connecting to ActiveMQ..."
      @aq = Stomp::Connection.new @client_hash

      @uuid = @aq.uuid()

      subscription_hash = {
        'id' => @uuid,
        'ack' => 'client-individual',
        'activemq.prefetchSize' => 1,
      }

      @logger.info "Subscribing to #{@destination}..."
      @aq.subscribe @destination, subscription_hash

      @last_update = Time.now
    end

    def listen
      @logger.info "Listening..."
      while true
        begin
          msg = nil
          Timeout::timeout(@update_interval) { msg = @aq.receive }
          next unless msg

          msgid = msg.headers['message-id']
          unless msgid
            @logger.warn ["Got message without message-id from ActiveMQ:",
                          '#v+', msg, '#v-'].join "\n"
            next
          end

          @logger.debug ["Received message #{msgid}:", '#v+', msg.body, '#v-'].join "\n"

          begin
            handle YAML.load(msg.body)
          rescue Psych::SyntaxError => e
            @logger.warn "Got #{e.class} exception while parsing message from ActiveMQ: #{e.message}"
            # Acknowledge it to get it out of the queue.
            @aq.ack msgid, {'subscription' => @uuid}
          rescue LBControllerException, LBModelException => e
            @logger.info "Got #{e.class} exception while handling message; sending NACK to ActiveMQ: #{e.message}"
            @aq.nack msgid, {'subscription' => @uuid}
          else
            @logger.debug 'Message handled; sending ACK to ActiveMQ.'
            @aq.ack msgid, {'subscription' => @uuid}
          end
        rescue Timeout::Error
        rescue Stomp::Error::NoCurrentConnection
          # The connection to activemq has gone away, attempt a reconnect
          @logger.debug 'Connection to ActiveMQ is gone, attempting a reconnect'
          connect
        rescue => e
          @logger.warn "Got #{e.class} exception while handling message: #{e.message}"
          @logger.debug "Backtrace:\n#{e.backtrace.join "\n"}"
        ensure
          update if Time.now - @last_update >= @update_interval
        end
      end
    end

    def handle event
      case event[:action]
      when :delete_application
        delete_application event[:app_name], event[:namespace]
      when :add_public_endpoint
        add_endpoint event[:app_name], event[:namespace], event[:public_address], event[:public_port], event[:types]
      when :remove_public_endpoint
        remove_endpoint event[:app_name], event[:namespace], event[:public_address], event[:public_port]
      when :add_alias
        add_alias event[:app_name], event[:namespace], event[:alias]
      when :remove_alias
        remove_alias event[:app_name], event[:namespace], event[:alias]
      when :add_ssl
        add_ssl event[:app_name], event[:namespace], event[:alias], event[:ssl], event[:private_key]
      when :remove_ssl
        remove_ssl event[:app_name], event[:namespace], event[:alias]
      end
    end

    def update
      @last_update = Time.now
      begin
        @lb_controller.update
      rescue => e
        @logger.warn "Got an exception: #{e.message}"
        @logger.debug "Backtrace:\n#{e.backtrace.join "\n"}"
      end
    end

    def generate_pool_name app_name, namespace
      @pool_name_format.gsub(/%./, '%a' => app_name, '%n' => namespace)
    end

    def generate_monitor_name app_name, namespace
      return nil unless @monitor_name_format

      @monitor_name_format.gsub(/%./, '%a' => app_name, '%n' => namespace)
    end

    def generate_monitor_path app_name, namespace
      return nil unless @monitor_path_format

      @monitor_path_format.gsub(/%./, '%a' => app_name, '%n' => namespace)
    end

    def with_pool app_name, namespace, create_if_nil=true
      pool_name = generate_pool_name app_name, namespace
      if @lb_controller.pools[pool_name].nil?
        @logger.info "Pool #{pool_name} unrecognized; resynching pools..."
        @lb_controller.synch_pools
      end

      if @lb_controller.pools[pool_name].nil?
        if create_if_nil
          create_application app_name, namespace, pool_name
        else
          @logger.info "Pool #{pool_name} not found; ignoring"
          return
        end
      end

      yield @lb_controller.pools[pool_name]
    end

    def create_application app_name, namespace, pool_name
      if @monitor_name_format && @monitor_name_format.match(/%a/) && @monitor_name_format.match(/%n/)
        monitor_name = generate_monitor_name app_name, namespace
        monitor_path = generate_monitor_path app_name, namespace
        unless monitor_name.nil? or monitor_name.empty? or monitor_path.nil? or monitor_path.empty?
          @logger.info "Creating new monitor #{monitor_name} with path #{monitor_path}"
          begin
            @lb_controller.create_monitor monitor_name, monitor_path, @monitor_up_code, @monitor_type, @monitor_interval, @monitor_timeout
          rescue LBControllerException => e
            @logger.warn "#{e.class}: #{e.message}"
          end
        end
      end

      @logger.info "Creating new pool: #{pool_name}"
      @lb_controller.create_pool pool_name, monitor_name

      alias_str = "#{@ha_dns_prefix}#{app_name}-#{namespace}.#{@cloud_domain}"
      @logger.info "Adding new alias #{alias_str} to pool #{pool_name}"
      @lb_controller.pools[pool_name].add_alias alias_str
    end

    def delete_application app_name, namespace
      with_pool app_name, namespace, false do |pool|
        @logger.info "Deleting pool: #{pool.name}"
        @lb_controller.delete_pool pool.name

        # Check that the monitor is specific to the application (as indicated by
        # having the application's name and namespace in the monitor's name).
        if @monitor_name_format && @monitor_name_format.match(/%a/) && @monitor_name_format.match(/%n/)
          monitor_name = generate_monitor_name app_name, namespace
          monitor_path = generate_monitor_path app_name, namespace
          unless monitor_name.nil? or monitor_name.empty? or monitor_path.nil? or monitor_path.empty?
            @logger.info "Deleting unused monitor: #{monitor_name}"
            # We pass pool.name to delete_monitor because some backends need the
            # name of the pool so that they will block the delete_monitor
            # operation until any corresponding delete_pool operation completes.
            @lb_controller.delete_monitor monitor_name, pool.name, @monitor_type
          end
        end
      end
    end

    def add_endpoint app_name, namespace, gear_host, gear_port, types
      with_pool app_name, namespace do |pool|
        unless (types & @endpoint_types).empty?
          @logger.info "Adding new member #{gear_host}:#{gear_port} to pool #{pool.name}"
          pool.add_member gear_host, gear_port.to_i
        else
          @logger.info "Ignoring endpoint with types #{types.join(',')}"
        end
      end
    end

    def remove_endpoint app_name, namespace, gear_host, gear_port
      with_pool app_name, namespace, false do |pool|
        member = gear_host + ':' + gear_port.to_s
        if not pool.members.include?(member)
          @logger.info "Pool member #{member} not found in pool #{pool.name}; resynching pool..."
          pool.synch
        end

        # The remove_endpoint notification does not include a "types" field, so we
        # cannot simply filter out endpoint types that we don't care about.
        # Furthermore, the daemon by design does not store state itself, so we
        # cannot check keep track of endpoints that we did not add to the load
        # balancer.  All we can do is check whether the endpoint exists and delete
        # it if it does.
        if pool.members.include?(member)
          @logger.info "Deleting member #{member} from pool #{pool.name}"
          pool.delete_member gear_host, gear_port.to_i
        else
          @logger.info "No member #{member} exists in pool #{pool.name}; ignoring"
        end
      end
    end

    def add_alias app_name, namespace, alias_str
      with_pool app_name, namespace do |pool|
        @logger.info "Adding new alias #{alias_str} to pool #{pool.name}"
        pool.add_alias alias_str
      end
    end

    def remove_alias app_name, namespace, alias_str
      with_pool app_name, namespace, false do |pool|
        @logger.info "Deleting alias #{alias_str} from pool #{pool.name}"
        pool.delete_alias alias_str
      end
    end

    def add_ssl app_name, namespace, alias_str, ssl_cert, private_key
      with_pool app_name, namespace do |pool|
        @logger.info "Adding ssl configuration for #{alias_str} in pool #{pool.name}"
        pool.add_ssl alias_str, ssl_cert, private_key
      end
    end

    def remove_ssl app_name, namespace, alias_str
      with_pool app_name, namespace, false do |pool|
        @logger.info "Deleting ssl configuration for #{alias_str} in pool #{pool.name}"
        pool.remove_ssl alias_str
      end
    end
  end

end
