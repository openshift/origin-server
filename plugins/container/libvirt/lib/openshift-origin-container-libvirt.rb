require "openshift-origin-node"
require "openshift/runtime/application_container_plugin/libvirt_container.rb"
OpenShift::Runtime::ApplicationContainer.container_plugin=OpenShift::Runtime::ApplicationContainerPlugin::LibvirtContainer