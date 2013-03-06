#
# Make Openshift
#
require 'rubygems'

module OpenShift

  # OpenShift DNS Plugin to interact with dynamic DNS using 
  # {https://www.ietf.org/rfc/rfc2136 RFC 2136} update protocol and
  # {https://www.ietf.org/rfc/rfc2845 RFC 2845} DNS TSIG
  #
  # Implements the OpenShift::DnsService interface
  #
  # This class uses the nsupdate(8) program to communicate with the
  # DNS service.
  #
  # The object can be configured either by providing the access_info
  # parameter or by pulling the settings from the Rails.application.config
  # object (if it exists).
  #
  # When pulling from the Rails configuration this plugin expects to find
  # the domain_suffix in 
  #   Rails.application.config.openshift[:domain_suffix]
  # and the rest of the parameters in a hash at
  #   Rails.application.config.dns
  #
  # @example Bind plugin configuration hash
  #   {:server => "myserver",
  #    :port => portnumber,
  #    :keyname => "TSIG key name",
  #    :keyvalue => "TSIG key string",
  #    :zone => "zone to update",
  #    # only when configuring with parameters
  #    :domain_suffix => "suffix for application domain names"
  #    }
  #
  # @!attribute [r] server
  #   @return [String] IP address of the DNS update server
  # @!attribute [r] port
  #   @return [Fixnum] UDP port for the DNS update server
  # @!attribute [r] keyname
  #   @return [String] the TSIG key name
  # @!attribute [r] keyvalue
  #   @return [String] the TSIG key value
  class NsupdatePlugin < OpenShift::DnsService
    @provider = OpenShift::NsupdatePlugin

    attr_reader :server, :port, :keyname, :keyvalue

    # Establish the parameters for a connection to the DNS update service
    #
    # @param access_info [Hash] communication configuration settings
    # @see BindPlugin BindPlugin class Examples
    def initialize(access_info = nil)
      if access_info != nil
        @domain_suffix = access_info[:domain_suffix]
      elsif defined? Rails
        access_info = Rails.application.config.dns
        @domain_suffix = Rails.application.config.openshift[:domain_suffix]
      else
        raise Exception.new("Nsupdate DNS updates are not initialized")
      end

      @server = access_info[:server]
      @port = access_info[:port].to_i
      @keyname = access_info[:keyname]
      @keyvalue = access_info[:keyvalue]
      @zone = access_info[:zone]
    end

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
      # create an A record for the application in the domain
      fqdn = "#{app_name}-#{namespace}.#{@domain_suffix}"
      raise DNSException.new unless system %{
nsupdate <<EOF
key #{@keyname} #{@keyvalue}
server #{@server} #{@port}
update add #{fqdn} 60 CNAME #{public_hostname}
send
quit
EOF
      }
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
      # delete the CNAME record for the application in the domain
      fqdn = "#{app_name}-#{namespace}.#{@domain_suffix}"
  
      #raise ::OpenShift::DNSNotFoundException.new unless dns_entry_exists?(fqdn, Dnsruby::Types::CNAME)
      raise DNSException.new unless system %{
nsupdate <<EOF
key #{@keyname} #{@keyvalue}
server #{@server} #{@port}
update delete #{fqdn} CNAME
send
quit
EOF
      }
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
      deregister_application(app_name, namespace)
      register_application(app_name, namespace, public_hostname)
    end

    # send any queued requests to the update server
    # @return [nil]
    def publish
    end

    # close any persistent connection to the update server
    # @return [nil]
    def close
    end

  end
end
