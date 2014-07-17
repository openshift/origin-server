module OpenShift
  class Username

    # "class" variable exists to be overridden by a plugin if needed
    @method_provider = OpenShift::Username
    def self.provider=(provider_class)
      @method_provider = provider_class
    end

    def self.normalize(login)
      @method_provider.normalize_impl(login)
    end

    # default implementation can be configured via broker.conf
    def self.normalize_impl(login)
      (Rails.configuration.openshift[:normalize_username_method] || 'noop').split(',').each do |method|
        method = method.strip.to_sym
        if respond_to?(method)
          login = send(method, login)
        else
          Rails.logger.warn "ERROR: No such method '#{method}' available in OpenShift::Username::normalize_impl"
        end
      end
      login
    end

    def self.noop(login)
      login.to_s
    end

    def self.strip(login)
      login.to_s.strip
    end

    def self.lowercase(login)
      login.to_s.downcase
    end

    def self.remove_domain(login)
      login = login.to_s
      if i = login.rindex('@')
        login[0,i]
      else
        login
      end
    end
  end
end
