module StickShift
  class DnsService
    @dns_provider = StickShift::DnsService

    def self.provider=(provider_class)
      @dns_provider = provider_class
    end

    def self.instance
      @dns_provider.new
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

    def publish
    end

    def close
    end
  end
end
