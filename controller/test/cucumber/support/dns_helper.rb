require 'rubygems'
require 'openshift-origin-controller'
require 'openshift-origin-dns-bind'

module DnsHelper
  #
  # Utility functions for checking namespace availability and removing dns entries
  #

  $dns_con = nil

  def dns_service
    if not $dns_con
      $dns_con = OpenShift::BindPlugin.new({:server => "127.0.0.1", 
                                         :port => 53,
                                         :keyname => "example.com", 
                                         :keyvalue => $bind_keyvalue,
                                         :domain_suffix => $domain, 
                                         :zone => "example.com"})
    end
    $dns_con
  end

  def namespace_available?(namespace)
    return dns_service.namespace_available?(namespace)
  end

  # Public: Removes DNS entries
  #
  # entries - The Array of entries to remove
  #
  # Examples
  #
  #   remove_dns_entries(['myapp-test2.dev.rhcloud.com'])
  #   # => true
  #
  # Returns entries Array on success
  def remove_dns_entries(entries=[])
    if not entries.empty?
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

end
World(DnsHelper)
