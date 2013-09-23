#
# When endpoints are exposed or concealed, publish an update to
# ActiveMQ.
#
require 'stomp'

module OpenShift
  class ActiveMQPlugin < OpenShift::RoutingService
    def initialize
      @topic = Rails.application.config.routing_activemq[:topic]
      @conn = Stomp::Connection.open Rails.application.config.routing_activemq[:username],
                                     Rails.application.config.routing_activemq[:password],
                                     Rails.application.config.routing_activemq[:host],
                                     Rails.application.config.routing_activemq[:port],
                                     true
    end

    def send_msg(msg)
      @conn.publish @topic, msg
    end

    def notify_create_application(app)
      msg = {
        :action => :create_application,
        :app_name => app.name,
        :namespace => app.domain.namespace,
      }
      send_msg msg.to_yaml
    end

    def notify_delete_application(app)
      msg = {
        :action => :delete_application,
        :app_name => app.name,
        :namespace => app.domain.namespace,
      }
      send_msg msg.to_yaml
    end

    def notify_create_public_endpoint(app, endpoint_name, public_ip, public_port)
      msg = {
        :action => :add_gear,
        :app_name => app.name,
        :namespace => app.domain.namespace,
        :public_port_name => endpoint_name,
        :public_address => public_ip,
        :public_port => public_port
      }
      send_msg msg.to_yaml
    end

    def notify_delete_public_endpoint(app, endpoint_name, public_ip, public_port)
      msg = {
        :action => :delete_gear,
        :app_name => app.name,
        :namespace => app.domain.namespace,
        :public_port_name => endpoint_name,
        :public_address => public_ip,
        :public_port => public_port
      }
      send_msg msg.to_yaml
    end
  end

end
