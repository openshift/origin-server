require "openshift-origin-common"

module OpenShift
  module McollectiveMsgBrokerModule
    require 'engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift/mcollective_application_container_proxy.rb"
OpenShift::ApplicationContainerProxy.provider=OpenShift::MCollectiveApplicationContainerProxy
