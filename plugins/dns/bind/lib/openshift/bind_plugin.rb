#
# Make OpenShift updates to a BIND DNS service
#
require 'rubygems'
require 'dnsruby'

module OpenShift

  #
  # OpenShift DNS Plugin to interact with dynamic DNS using 
  # {https://www.ietf.org/rfc/rfc2136 RFC 2136} update protocol and
  # {https://www.ietf.org/rfc/rfc2845 RFC 2845} DNS TSIG
  #
  # Implements the OpenShift::DnsService interface
  #
  # This service uses the Ruby Dnsruby package to communicate with the
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
  class BindPlugin < OpenShift::DnsService

    attr_reader :server, :port, :keyname, :keyvalue

    # class variable: 
    @oo_dns_provider = OpenShift::BindPlugin


    # Establish the parameters for a connection to the DNS update service
    #
    # @param access_info [Hash] communication configuration settings
    # @see BindPlugin BindPlugin class Examples
    def initialize(access_info = nil)

      if access_info != nil
        @domain_suffix = access_info[:domain_suffix]
      elsif defined? Rails
        # extract from Rails.application.config[dns,ss]
        access_info = Rails.application.config.dns
        @domain_suffix = Rails.application.config.openshift[:domain_suffix]
      else
        raise Exception.new("BIND DNS service is not initialized")
      end
      @server = access_info[:server]
      @port = access_info[:port].to_i
      @src_port = access_info[:src_port].to_i if access_info[:src_port].to_i
      @keyname = access_info[:keyname]
      @keyvalue = access_info[:keyvalue]
      @zone = access_info[:zone]
    end

    private

    # create a resolver object - connection to the update server
    #
    # @return [Dnsruby::Resolver] a resolver object for the update service
    def dns
      if not @dns_con
        @dns_con = Dnsruby::Resolver.new(:nameserver => @server, :port => @port)
        @dns_con.src_port = @src_port if @src_port
      end
      @dns_con
    end

    public


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
      # enable updates with key
      dns.tsig = @keyname, @keyvalue

      update = Dnsruby::Update.new(@zone)
      update.add(fqdn, 'CNAME', 60, public_hostname)
      dns.send_message(update)
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
      begin
        # delete the CNAME record for the application in the domain
        fqdn = "#{app_name}-#{namespace}.#{@domain_suffix}"
  
        # We know we only have one CNAME per app, so look it up
        # We need it for the delete
        # should be an error if there's not exactly one answer
        current = dns.query(fqdn, 'CNAME')
        cnamevalue = current.answer[0].rdata.to_s        
  
        # enable updates with key
        dns.tsig = @keyname, @keyvalue
        update = Dnsruby::Update.new(@zone)
        update_response = update.delete(fqdn, 'CNAME', cnamevalue)
        send_response = dns.send_message(update)
      rescue Dnsruby::NXDomain
        Rails.logger.debug "DEBUG: BIND: Could not find CNAME for #{fqdn} to delete"
      end
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
