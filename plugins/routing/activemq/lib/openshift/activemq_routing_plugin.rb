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
      @login = Rails.application.config.routing_activemq[:username]
      @passcode = Rails.application.config.routing_activemq[:password]
      @hosts = Rails.application.config.routing_activemq[:hosts]
      if Rails.application.config.routing_activemq[:debug]
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
      @conn = Stomp::Connection.open({
        :hosts => @hosts.map do |host|
          host.merge({
            :login => @login,
            :passcode => @passcode,
          })
        end,
      })
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
