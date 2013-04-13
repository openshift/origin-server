require 'openshift-origin-controller'
require 'rails'

module OpenShift
  class ActiveMQRoutingEngine < ::Rails::Engine
    config.after_initialize do
      OpenShift::RoutingService.register_provider OpenShift::ActiveMQPlugin.new
    end
  end
end
