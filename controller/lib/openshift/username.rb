module OpenShift
  class Username

    # "class" variable exists to be overridden by a plugin if needed
    @method_provider = OpenShift::Username
    def self.provider=(provider_class)
      @method_provider = provider_class
    end

    def self.normalize(login)
      # Normalization should ideally be idempotent or there will be problems
      # when a stored normalization is retrieved and re-normalized.
      normal = login
      10.times do # Make sure by normalizing until it stays the same.
        normaler = @method_provider.normalize_impl(normal)
        return normal if normal == normaler # same, done normalizing
        normal = normaler
      end
      raise OpenShift::OOException.new("Login normalization should be idempotent. Could not normalize '#{login}'")
    end

    # A custom implementation can be inserted with provider=
    # This default implementation can be configured via broker.conf
    def self.normalize_impl(login)
      (Rails.configuration.openshift[:normalize_username_method] || 'noop').split(',').each do |method|
        method = method.strip.to_sym
        if respond_to?(method)
          login = send(method, login)
        else
          Rails.logger.error "No such method '#{method}' available in OpenShift::Username::normalize_impl"
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
      if i = login.index('@')
        login[0,i]
      else
        login
      end
    end
  end
end
