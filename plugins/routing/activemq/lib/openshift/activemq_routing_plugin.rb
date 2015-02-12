#
# When endpoints are exposed or concealed, publish an update to
# ActiveMQ.
#
require 'stomp'

module OpenShift
  class ActiveMQPlugin < OpenShift::RoutingService
    def initialize
      Rails.logger.debug("Listening for routing events")
      @dest = Rails.application.config.routing_activemq[:destination]
      @hosts = Rails.application.config.routing_activemq[:hosts]
      @mcollective_conf = Rails.application.config.routing_activemq[:mcollective_conf]

      # If the MCOLLECTIVE_CONFIG setting is found in the routing plugin config, read settings from MCollective client config
      unless @mcollective_conf.nil?
        Rails.logger.debug("ACTIVEMQ_HOSTS settings is now being overridden by MCollective client config settings because you set MCOLLECTIVE_CONFIG")
        @mcollective_conf = OpenShift::Config.new(@mcollective_conf)
        @plugin_prefix = "plugin.activemq.pool."
        pools = @mcollective_conf.get("#{@plugin_prefix}size").to_i
        @hosts = []

        1.upto(pools) do |poolnum|
          host = {}

          host[:host] = @mcollective_conf.get("#{@plugin_prefix}#{poolnum}.host")
          host[:port] = @mcollective_conf.get("#{@plugin_prefix}#{poolnum}.port", 61613).to_i
          host[:ssl] = @mcollective_conf.get_bool("#{@plugin_prefix}#{poolnum}.ssl", "false")
          host[:ssl] = ssl_parameters(poolnum, @mcollective_conf.get_bool("#{@plugin_prefix}#{poolnum}.ssl.fallback", "false")) if host[:ssl]

          Rails.logger.debug("Adding #{host[:host]}:#{host[:port]} to the connection pool")
          @hosts << host
        end
      end

      # Credentials are read from the plugin configuration and not the MCollective client.cfg since these are the routing credentials.
      @hosts = @hosts.map do |host|
        host.merge({
          :login => Rails.application.config.routing_activemq[:username],
          :passcode => Rails.application.config.routing_activemq[:password],
        })
      end

      if Rails.application.config.routing_activemq[:debug]
        @conn = Class.new(Object) do
          def publish(dest, msg)
            Rails.logger.debug("Destination #{dest} gets message:\n#{msg}")
          end
        end.new
      end
    end

    def ssl_parameters(poolnum, fallback)
	params = {:cert_file =>  @mcollective_conf.get("#{@plugin_prefix}#{poolnum}.ssl.cert"),
		  :key_file => @mcollective_conf.get("#{@plugin_prefix}#{poolnum}.ssl.key"),
		  :ts_files  => @mcollective_conf.get("#{@plugin_prefix}#{poolnum}.ssl.ca")}

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
	  Rails.logger.warn("Failed to set full SSL verified mode, falling back to unverified: #{e.class}: #{e}")
	  return true
	else
	  Rails.logger.error("Failed to set full SSL verified mode: #{e.class}: #{e}")
	  raise(e)
	end
    end

    def send_msg(msg)
      # Reinitializing connection to avoid a missing message in a failover
      # scenario https://bugzilla.redhat.com/show_bug.cgi?id=1128857
      @conn = Stomp::Connection.open({ :hosts => @hosts })
      @conn.publish @dest, msg
      @conn.disconnect
    end

    def notify_ssl_cert_add(app, fqdn, ssl_cert, pvt_key, passphrase)
      msg = {
        :action => :add_ssl,
        :app_name => app.name,
        :namespace => app.domain_namespace,
        :alias => fqdn,
        :ssl => ssl_cert,
        :private_key => pvt_key,
        :pass_phrase => passphrase
      }
      send_msg msg.to_yaml
    end

    def notify_ssl_cert_remove(app, fqdn)
      msg = {
        :action => :remove_ssl,
        :app_name => app.name,
        :namespace => app.domain_namespace,
        :alias => fqdn
      }
      send_msg msg.to_yaml
    end

    def notify_add_alias(app, alias_str)
      msg = {
        :action => :add_alias,
        :app_name => app.name,
        :namespace => app.domain_namespace,
        :alias => alias_str
      }
      send_msg msg.to_yaml
    end

    def notify_remove_alias(app, alias_str)
      msg = {
        :action => :remove_alias,
        :app_name => app.name,
        :namespace => app.domain_namespace,
        :alias => alias_str
      }
      send_msg msg.to_yaml
    end

    def notify_create_application(app)
      msg = {
        :action => :create_application,
        :app_name => app.name,
        :namespace => app.domain.namespace,
        :scalable => app.scalable,
        :ha => app.ha,
      }
      send_msg msg.to_yaml
    end

    def notify_delete_application(app)
      msg = {
        :action => :delete_application,
        :app_name => app.name,
        :namespace => app.domain.namespace,
        :scalable => app.scalable,
        :ha => app.ha,
      }
      send_msg msg.to_yaml
    end

    def notify_create_public_endpoint(app, gear, endpoint_name, public_ip, public_port, protocols, types, mappings)
      msg = {
        :action => :add_public_endpoint,
        :app_name => app.name,
        :namespace => app.domain.namespace,
        :gear_id => gear._id.to_s,
        :public_port_name => endpoint_name,
        :public_address => public_ip,
        :public_port => public_port.to_i,
        :protocols => protocols,
        :types => types,
        :mappings => mappings
      }
      send_msg msg.to_yaml
    end

    def notify_delete_public_endpoint(app, gear, public_ip, public_port)
      msg = {
        :action => :remove_public_endpoint,
        :app_name => app.name,
        :namespace => app.domain.namespace,
        :gear_id => gear._id.to_s,
        :public_address => public_ip,
        :public_port => public_port.to_i
      }
      send_msg msg.to_yaml
    end
  end

end
