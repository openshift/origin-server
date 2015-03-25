#
# When endpoints are exposed or concealed, publish an update to
# ActiveMQ.
#
require 'stomp'

module OpenShift
  class ActiveMQSsoPlugin < OpenShift::SsoService
    def initialize
      Rails.logger.debug("Listening for sso events")
      @dest = Rails.application.config.sso_activemq[:destination]
      @hosts = Rails.application.config.sso_activemq[:hosts]
      @mcollective_conf = Rails.application.config.sso_activemq[:mcollective_conf]

      # If the MCOLLECTIVE_CONFIG setting is found in the sso plugin config, read settings from MCollective client config
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

      # Credentials are read from the plugin configuration and not the MCollective client.cfg since these are the sso credentials.
      @hosts = @hosts.map do |host|
        host.merge({
          :login => Rails.application.config.sso_activemq[:username],
          :passcode => Rails.application.config.sso_activemq[:password],
        })
      end

      if Rails.application.config.sso_activemq[:debug]
        @conn = Class.new(Object) do
          def publish(dest, msg)
            Rails.logger.debug("Destination #{dest} gets message:\n#{msg}")
          end
        end.new
      end
    end

    def send_msg(msg)
      # Reinitializing connection to avoid a missing message in a failover
      # scenario https://bugzilla.redhat.com/show_bug.cgi?id=1128857
      @conn = Stomp::Connection.open({ :hosts => @hosts })
      @dest.split(':').each do |d|
        @conn.publish d, msg
      end
      @conn.disconnect
    end

    def prep_msg(gear,environ=false)
      app = gear.application

      gprops = GearProperties.new(gear)

      msg = {
        :app_id => app._id.to_s,
        :app_name => gear.name,
        :domain => Rails.configuration.openshift[:domain_suffix],
	:gear_id => gear._id.to_s,
        :namespace => app.domain.namespace,
        :scalable => app.scalable,
        :server => gear.public_hostname,
        :district => gprops.district,
        :cartridges => gprops.cartridges,
      }

      msg[:region] = gprops.region if gprops.region
      msg[:zone] = gprops.zone if gprops.zone

      env = {}

      if environ
        app.domain.env_vars.each do |nv|
          env[nv['key']] = nv['value']
        end
        env = env.merge(app.list_user_env_variables)
        if env.length > 0
          msg[:env_vars] = env
        end
      end

      Rails.logger.info("activemq_sso #{gear.name}-#{app.domain.namespace} #{env.inspect}")

      aliases = []
      app.aliases.each do |a|
        aliases.push(a.fqdn.to_s)
      end
      if aliases.length > 0
        msg[:aliases] = aliases
      end
      if app.ha
        ha_dns_prefix = Rails.configuration.openshift[:ha_dns_prefix]
        ha_dns_suffix = Rails.configuration.openshift[:ha_dns_suffix]
        msg[:ha_app_name] = "#{ha_dns_prefix}#{app.name}-#{app.domain.namespace}#{ha_dns_suffix}"
      end

      msg
    end

    def deregister_gear(gear)
      Rails.logger.info("activemq_sso deregister_gear #{gear.name}")

      msg = prep_msg(gear,false)
      msg[:action] = :deregister_gear

      send_msg msg.to_yaml
    end

    def register_gear(gear)
      Rails.logger.info("activemq_sso register_gear #{gear.name}")

      msg = prep_msg(gear,true)
      msg[:action] = :register_gear

      send_msg msg.to_yaml
    end

    def deregister_alias(gear,alias_str)

      Rails.logger.info("activemq_sso deregister_alias #{gear.name} #{alias_str}")

      msg = prep_msg(gear,true)
      msg[:action] = :deregister_alias
      msg[:remove_alias] = alias_str

      send_msg msg.to_yaml
    end

  end

end
