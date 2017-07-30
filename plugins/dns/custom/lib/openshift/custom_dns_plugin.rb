#
# Make Openshift
#
require 'rubygems'

module OpenShift

  class CustomDNSPlugin < OpenShift::DnsService

    @provider = OpenShift::CustomDNSPlugin

    attr_reader :dns_custom_script


    # Establish the parameters for a connection to the DNS update service
    #
    # @param access_info [Hash] communication configuration settings
    #
    def initialize(access_info = nil)

      if access_info != nil
        @domain_suffix = access_info[:domain_suffix]

      elsif defined? Rails
        access_info = Rails.application.config.dns
        @domain_suffix = Rails.application.config.openshift[:domain_suffix]

      else
        raise DNSException.new("Custom DNS plugin did not initialize")
      end

      @dnsscript = access_info[:dns_custom_script]

    end


##    public

    # Publish an application - create DNS record
    #
    # @param [String] app_name         The name of the application to publish
    # @param [String] namespace        The namespace which contains the application
    # @param [String] public_hostname  The name of the location where the application resides
    # @return [Object]                 The response from the service provider
    #
    def register_application(app_name, namespace, public_hostname)

      # create an A record for the application in the domain
      fqdn = "#{app_name}-#{namespace}.#{@domain_suffix}"
      cmd = add_cmd(fqdn, public_hostname)

      modify_dns(cmd, "adding", fqdn)
    end


    # Unpublish an application - remove DNS record
    #
    # @param [String] app_name         The name of the application to publish
    # @param [String] namespace        The namespace which contains the application
    # @return [Object]                 The response from the service provider
    #
    def deregister_application(app_name, namespace)

      # delete the CNAME record for the application in the domain
      fqdn = "#{app_name}-#{namespace}.#{@domain_suffix}"
      cmd = del_cmd(fqdn)

      modify_dns(cmd, "removing", fqdn)
    end


    # Change the published location of an application - Modify DNS record
    #
    # @param [String] app_name         The name of the application to publish
    # @param [String] namespace        The namespace which contains the application
    # @param [String] public_hostname  The name of the location where the application resides
    # @return [Object]                 The response from the service provider
    #
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


    private
    
    # Generate a DNS add command string
    # 
    # @param fqdn [String]  DNS record name to add
    # @param value [String] DNS record value
    # @return [String]      An nsupdate command sequence
    #
    def add_cmd(fqdn, value)

      # compose the DNS add command
      cmd = "#{@dnsscript} --action add --cname #{fqdn} --host #{value} 2>&1"

    end


    # Generate a DNS delete command string
    # 
    # @param fqdn [String]  DNS record name to delete
    # @return [String]      An nsupdate command sequence
    #
    def del_cmd(fqdn)

      # compose the DNS add command
      cmd = "#{@dnsscript} --action delete --cname #{fqdn} 2>&1"

    end
   

    # Run an nsupdate command, returning a detailed error on failure
    #
    # @param cmd [String]     Command sequence to add the DNS CNAME entry
    # @param action [String]  Action to be reported in log message ("adding" or "removing")
    # @param fqdn             FQDN of the application
    #
    def modify_dns(cmd, action, fqdn)

      Rails.logger.info "[modify-dns]: #{action} DNS application record #{fqdn}: cmd=#{cmd}"

      output = `#{cmd}`
      exit_code = $?.exitstatus

      if exit_code != 0
        Rails.logger.error "[modify-dns]: Error #{action} DNS application record #{fqdn}: #{output}"
        raise DNSException.new("[modify-dns]: Error #{action} DNS application record #{fqdn} rc=#{exit_code}")
      end
    end


  end
end
