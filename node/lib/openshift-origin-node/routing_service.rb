module OpenShift

  # Abstract routing plug-in interface.
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
      @routing_provider.each { |p| p.send(event, *args) if p.respond_to?(event) }
    end

    def self.notify_adding_public_endpoint(app, endpoint, public_port)
      notify_providers :adding_public_endpoint, app, endpoint, public_port
    end

    def self.notify_deleting_public_endpoint(app, endpoint, public_port)
      notify_providers :deleting_public_endpoint, app, endpoint, public_port
    end

    #def initialize
    #end

    # Expose a new public endpoint.
    #
    # @param [OpenShift::ApplicationContainer] app
    #   The application to which the endpoint routes.
    # @param [OpenShift::Runtime::Cartridge::Endpoint] endpoint
    #   The new endpoint.
    # @param [Integer] public_port
    #   The public port assigned to the endpoint by port-proxy.
    # @return [Object]
    #   The response from the service provider in what ever form
    #   that takes.
    def adding_public_endpoint(app, endpoint, public_port)
    end

    # Delete an existing public endpoint.
    #
    # @param [OpenShift::ApplicationContainer] app
    #   The application to which the endpoint routes.
    # @param [OpenShift::Runtime::Cartridge::Endpoint] endpoint
    #   The new endpoint.
    # @param [Integer] public_port
    #   The public port assigned to the endpoint by port-proxy.
    # @return [Object]
    #   The response from the service provider in what ever form
    #   that takes 
    def deleting_public_endpoint(app, endpoint, public_port)
    end
  end

end
