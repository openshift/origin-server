# Openshift Origin DNS plugin: DNSMasq
#
# The superclass StickShift::DnsService is defined in stickshift-controller
require "stickshift-controller"

# import the actual class definition and interface implementation
require "uplift-dnsmasq-plugin/uplift/dnsmasq_plugin.rb"

# initialize the superclass factory provider with the implementation class
#StickShift::DnsService.provider=Uplift::DnsMasqPlugin

