module StickShift
  class DnsService
    @ss_dns_provider = StickShift::DnsService

    def self.provider=(provider_class)
      @ss_dns_provider = provider_class
    end

    def self.instance
      @ss_dns_provider.new
    end

    def initialize
    end

    def namespace_available?(namespace)
      return true
    end

    def register_namespace(namespace)
    end

    def deregister_namespace(namespace)
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
