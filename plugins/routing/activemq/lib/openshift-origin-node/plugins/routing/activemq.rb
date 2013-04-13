#
# When endpoints are exposed or concealed, publish an update to
# ActiveMQ.
#
require 'rubygems'
require 'stomp'
require 'openshift-origin-common'
require 'openshift-origin-node/config'
require 'openshift-origin-node/model/unix_user'
require 'openshift-origin-node/model/application_container'
require 'openshift-origin-node/routing_service'

module OpenShift
  class ActiveMQPlugin < OpenShift::RoutingService
    def initialize
      @conf = OpenShift::Config.instance
      @topic = @conf.get("PLUGIN_ROUTING_ACTIVEMQ_TOPIC", "/topic/routing")
      @conn = Stomp::Connection.open @conf.get("PLUGIN_ROUTING_ACTIVEMQ_USERNAME", "routinginfo"),
                                     @conf.get("PLUGIN_ROUTING_ACTIVEMQ_PASSWORD", "routinginfopasswd"),
                                     @conf.get("PLUGIN_ROUTING_ACTIVEMQ_HOST", "127.0.0.1"),
                                     @conf.get("PLUGIN_ROUTING_ACTIVEMQ_PORT", "61613"),
                                     true
    end

    def send_msg(msg)
      @conn.publish @topic, msg
    end

    def adding_public_endpoint(app, endpoint, public_port)
      msg = {
        :action => :add,
        :app_name => app.user.app_name,
        :namespace => app.user.namespace,
        :public_port_name => endpoint.public_port_name,
        :public_address => @conf.get("PUBLIC_IP"),
        :public_port => public_port
      }
      send_msg msg.to_yaml
    end

    def deleting_public_endpoint(app, endpoint, public_port)
      msg = {
        :action => :delete,
        :app_name => app.user.app_name,
        :namespace => app.user.namespace,
        :public_port_name => endpoint.public_port_name,
        :public_address => @conf.get("PUBLIC_IP"),
        :public_port => public_port
      }
      send_msg msg.to_yaml
    end
  end

end

OpenShift::RoutingService.register_provider OpenShift::ActiveMQPlugin.new
