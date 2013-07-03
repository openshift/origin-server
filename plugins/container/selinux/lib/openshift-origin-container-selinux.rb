require "openshift-origin-node"
require "openshift/runtime/containerization/selinux_container.rb"
OpenShift::Runtime::ApplicationContainer.container_plugin=OpenShift::Runtime::Containerization::SELinuxContainer