require 'rubygems'
require 'dnsruby'

class NameServerCache
  
  def self.get_cached(key, opts={})
    unless Rails.configuration.action_controller.perform_caching
      if block_given?
        return yield
      end
    end

    val = Rails.cache.read(key)
    unless val
      if block_given?
        val = yield
        if val
          Rails.cache.write(key, val, opts)
        end
      end
    end

    return val
  end

  def self.get_name_servers
    dns = Dnsruby::DNS.new()
    resources = dns.getresources(Rails.application.config.openshift[:domain_suffix], Dnsruby::Types.NS)
    @nameservers = []
    resources.each do |resource|
      @nameservers.push(resource.domainname.to_s)
    end                
    get_cached("name_servers", :expires_in => 1.hour) {@nameservers}
  end
end
