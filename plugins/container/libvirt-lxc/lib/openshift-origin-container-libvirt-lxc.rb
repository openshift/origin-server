require "openshift-origin-node"
require "openshift/container/libvirt_lxc_container.rb"
OpenShift::ApplicationContainer.provider=OpenShift::Container::LibVirtLxcContainer