#
# When endpoints are exposed or concealed, publish an update to
# ActiveMQ.
#
require 'stomp'

module OpenShift
  class ActiveMQPlugin < OpenShift::RoutingService
    def initialize
      Rails.logger.debug("Listening for routing events")
      @topic = Rails.application.config.routing_activemq[:topic]
      if Rails.application.config.routing_activemq[:debug]
        @conn = Class.new(Object) do
          def publish(topic, msg)
            Rails.logger.debug("Topic #{topic} gets message:\n#{msg}")
          end
        end.new
      else
        @conn = Stomp::Connection.open Rails.application.config.routing_activemq[:username],
                                       Rails.application.config.routing_activemq[:password],
                                       Rails.application.config.routing_activemq[:host],
                                       Rails.application.config.routing_activemq[:port],
                                       true
      end
    end

    def send_msg(msg)
      @conn.publish @topic, msg
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
      # DEPRECATED, will be removed in OSE 2.2 / Origin 4
      msg[:action] = :add_gear
      msg[:deprecated] = "use add_public_endpoint"
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
      # DEPRECATED, will be removed in OSE 2.2 / Origin 4
      msg[:action] = :delete_gear
      msg[:deprecated] = "use remove_public_endpoint"
      send_msg msg.to_yaml
    end
  end

end
