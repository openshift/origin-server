module OpenShift

  # Routing singleton, manages notifications of changes to routes.
  #
  # An optional routing plug-in may be used to communicate with
  # infrastructure outside of OpenShift, such as an external load
  # balancer or firewall.
  #
  # Multiple routing plug-ins may be registered at the same time,
  # or there may be none registered.
  #
  # This class defines the abstract interface that plug-ins can
  # implement in order to integrate with the external environment.
  #
  # This class also proxies method calls to all registered plug-ins.
  class RoutingService

    @routing_provider = []

    # Register a provider object to which method calls will be proxied.
    #
    # @param [Object] provider
    #   An object to which method calls will be proxied.
    # @return [[Object]]
    #   The list of classes to which method calls will be proxied.
    def self.register_provider(provider)
      @routing_provider << provider
    end

    # Deregister a previously registered provider.
    #
    # @param [Object] provider
    #   An object to be removed from the list of providers.
    # @return [Object]
    #   The deregistered object, or nil if the object was not found to
    #   have been previously registered.
    def self.deregister_provider(provider)
      @routing_provider.delete provider
    end

    # Notify provider objects of an event.
    def self.notify_providers(event, *args)
      @routing_provider.each{ |p| p.send(event, *args) if p.respond_to?(event) }
    end

    def self.notify_ssl_cert_add(app, fqdn, ssl_cert, private_key, passphrase)
      notify_providers :notify_ssl_cert_add, app, fqdn, ssl_cert, private_key, passphrase
    end

    def self.notify_ssl_cert_remove(app, fqdn)
      notify_providers :notify_ssl_cert_remove, app, fqdn
    end

    def self.notify_add_alias(app, alias_str)
      notify_providers :notify_add_alias, app,alias_str
    end

    def self.notify_remove_alias(app, alias_str)
      notify_providers :notify_remove_alias, app,alias_str
    end

    def self.notify_create_application(app)
      notify_providers :notify_create_application, app
    end

    def self.notify_delete_application(app)
      notify_providers :notify_delete_application, app
    end

    def self.notify_create_public_endpoint(app, gear, endpoint_name, public_ip, public_port, internal_ip, internal_port, protocols, types, mappings)
      notify_providers :notify_create_public_endpoint, app, gear, endpoint_name, public_ip, public_port, protocols, types, mappings
    end

    def self.notify_delete_public_endpoint(app, gear, public_ip, public_port)
      notify_providers :notify_delete_public_endpoint, app, gear, public_ip, public_port
    end
  end
end
