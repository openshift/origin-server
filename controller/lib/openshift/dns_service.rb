module OpenShift

  # Abstract DNS update plugin interface
  #
  # The DNS update plugin communicates with a dynamic DNS service to publish
  # the locations of new applications.
  #
  # This class defines the abstract interface that will be implemented by
  # plugins which interact with real services.
  #
  # This class also acts as a factory for the plugin service objects.
  #
  # @abstract
  class DnsService
    @oo_dns_provider = OpenShift::DnsService

    # Set the concrete provider class for the plugin object factory
    # @param [Class <DnsService>] provider_class
    #   The class to instantiate when an instance is requested
    # @return [Class <DnsService>]
    #   The class which has been set in the factory
    def self.provider=(provider_class)
      @oo_dns_provider = provider_class
    end

    # Factory method for plugin implementation objects
    # @return [DnsService] 
    #   an object which implements the DnsService interface
    def self.instance
      @oo_dns_provider.new
    end

    #def initialize
    #end

    # Publish an application - create DNS record
    #
    # @param [String] app_name
    #   The name of the application to publish
    # @param [String] namespace
    #   The namespace which contains the application
    # @param [String] public_hostname
    #   The name of the location where the application resides
    # @return [Object]
    #   The response from the service provider in what ever form
    #   that takes
    def register_application(app_name, namespace, public_hostname)
    end

    # Unpublish an application - remove DNS record
    #
    # @param [String] app_name
    #   The name of the application to publish
    # @param [String] namespace
    #   The namespace which contains the application
    # @return [Object]
    #   The response from the service provider in what ever form
    #   that takes    
    def deregister_application(app_name, namespace)
    end

    # Change the published location of an application - Modify DNS record
    #
    # @param [String] app_name
    #   The name of the application to publish
    # @param [String] namespace
    #   The namespace which contains the application
    # @param [String] public_hostname
    #   The name of the location where the application resides
    # @return [Object]
    #   The response from the service provider in what ever form
    #   that takes
    def modify_application(app_name, namespace, public_hostname)
    end

    # Send any queued update requests to the DNS update service
    # @return [nil]
    def publish
    end

    # Terminate any open connection to the DNS update service
    # @return [nil]
    def close
    end
  end
end
