require "openshift-origin-common"
require "openshift-origin-dns-bind/openshift/bind_plugin.rb"
OpenShift::DnsService.provider=OpenShift::BindPlugin
