require "openshift-origin-node"
require "openshift/runtime/containerization/libvirt_container.rb"
OpenShift::Runtime::ApplicationContainer.container_plugin=OpenShift::Runtime::Containerization::LibvirtContainer