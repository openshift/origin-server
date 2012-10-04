require "openshift-origin-common"
require "uplift-bind-plugin/uplift/bind_plugin.rb"
OpenShift::DnsService.provider=OpenShift::BindPlugin
