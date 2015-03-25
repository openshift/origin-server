require 'openshift-origin-controller'
require 'rails'

module OpenShift
  class ActiveMQSsoEngine < ::Rails::Engine
    config.after_initialize do
      OpenShift::SsoService.register_provider OpenShift::ActiveMQSsoPlugin.new
    end
  end
end
