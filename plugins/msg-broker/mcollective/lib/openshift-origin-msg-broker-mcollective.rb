require "openshift-origin-common"

module OpenShift
  module McollectiveMsgBrokerModule
    require 'openshift-origin-msg-broker-mcollective/engine/engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift-origin-msg-broker-mcollective/lib/openshift/mcollective_application_container_proxy.rb"
OpenShift::ApplicationContainerProxy.provider=OpenShift::MCollectiveApplicationContainerProxy