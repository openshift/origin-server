require 'rubygems'
require 'stickshift-controller'
require 'uplift-bind-plugin'

module DnsHelper
  #
  # Utility functions for checking namespace availability and removing dns entries
  #
  def dns_service
    if not @dns_con
      @dns_con = Uplift::BindPlugin.new({:server => "127.0.0.1", 
                                         :port => 53,
                                         :keyname => "example.com", 
                                         :keyvalue => "lOuqTjZbxrFwOodiqXMcBQ8J5bGNvU6xUgOQxOohSRmiSi49P56x/wVNd/0kqmLvUxjt3qzx0lVCsFnxaRgg7g==", 
                                         :domain_suffix => $domain, 
                                         :zone => "example.com"})
    end
    @dns_con
  end

  def namespace_available?(namespace)
    return dns_service.namespace_available?(namespace)
  end

  def remove_dns_entries(entries=[])
    entries.each do |domain|
      yes = dns_service.namespace_available?(domain)
      if !yes
      #puts "deregistering #{domain}"
      dns_service.deregister_namespace(domain)
      end
    end
    dns_service.publish
    dns_service.close
  end

end
World(DnsHelper)