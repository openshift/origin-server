require 'openshift-origin-controller'
require 'rails'

module OpenShift
  class McollectiveMsgBrokerEngine < Rails::Engine
    paths.lib                  << "lib/openshift-origin-msg-broker-mcollective/lib"
    paths.config               << "lib/openshift-origin-msg-broker-mcollective/config"
    config.autoload_paths      += %W(#{config.root}/lib)
  end
end