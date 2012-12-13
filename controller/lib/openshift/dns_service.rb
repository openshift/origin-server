module OpenShift
  class DnsService
    @oo_dns_provider = OpenShift::DnsService

    def self.provider=(provider_class)
      @oo_dns_provider = provider_class
    end

    def self.instance
      @oo_dns_provider.new
    end

    def initialize
    end

    def register_application(app_name, namespace, public_hostname)
    end

    def deregister_application(app_name, namespace)
    end
    
    def modify_application(app_name, namespace, public_hostname)
    end

    def publish
    end

    def close
    end
  end
end
