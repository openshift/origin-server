require "openshift-origin-common"
require "msg-broker-mcollective-plugin/msg-broker/mcollective_application_container_proxy.rb"
OpenShift::::ApplicationContainerProxy.provider=OpenShift::MCollectiveApplicationContainerProxy
