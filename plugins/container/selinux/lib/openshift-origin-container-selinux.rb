require "openshift-origin-node"
require "openshift/container/selinux_container.rb"
OpenShift::ApplicationContainer.provider=OpenShift::Container::SELinuxContainer