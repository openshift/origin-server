module OpenShift

  # SSO singleton, manages notifications of changes to gears and aliases.
  #
  # An optional sso plug-in may be used to communicate with
  # infrastructure outside of OpenShift, such as an external SSO
  # server.
  #
  # Multiple sso plug-ins may be registered at the same time,
  # or there may be none registered.
  #
  # This class defines the abstract interface that plug-ins can
  # implement in order to integrate with the external environment.
  #
  # This class also proxies method calls to all registered plug-ins.
  class SsoService

    @sso_provider = []

    # Register a provider object to which method calls will be proxied.
    #
    # @param [Object] provider
    #   An object to which method calls will be proxied.
    # @return [[Object]]
    #   The list of classes to which method calls will be proxied.
    def self.register_provider(provider)
      @sso_provider << provider
    end

    # Deregister a previously registered provider.
    #
    # @param [Object] provider
    #   An object to be removed from the list of providers.
    # @return [Object]
    #   The deregistered object, or nil if the object was not found to
    #   have been previously registered.
    def self.deregister_provider(provider)
      @sso_provider.delete provider
    end

    # Notify provider objects of an event.
    def self.notify_providers(event, *args)
      @sso_provider.each{ |p| p.send(event, *args) if p.respond_to?(event) }
    end

    def self.register_gear(gear)
      notify_providers :register_gear, gear
    end

    def self.deregister_gear(gear)
      notify_providers :deregister_gear, gear
    end

    def self.deregister_alias(app, alias_str)
      notify_providers :deregister_alias, app, alias_str
    end

  end
end
