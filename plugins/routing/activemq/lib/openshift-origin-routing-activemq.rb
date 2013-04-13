module OpenShift
  module ActiveMQRoutingModule
    require 'activemq_routing_engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift/activemq_routing_plugin.rb"
