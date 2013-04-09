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
  # @example nsupdate plugin configuration hash - HMAC-MD5 TSIG
  #   {:server => "myserver",
  #    :port => portnumber,
  #    :keyname => "TSIG key name",
  #    :keyvalue => "TSIG key string",
  #    :zone => "zone to update",
  #    # only when configuring with parameters
  #    :domain_suffix => "suffix for application domain names"
  #    }
  #
  # @example nsupdate plugin configuration hash - KRB5 GSS-TSIG
  #   {:server => "myserver",
  #    :port => portnumber,
  #    :krb_principal => "The authentication principal",
  #    :krb_keytab => "The authentication key",
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
  # @!attribute [r] krb_principal
  #   @return [String] A Kerberos 5 principal
  # @!attribute [r] krb_keytab
  #   @return [String] the Kerberos keytab
  #
  class NsupdatePlugin < OpenShift::DnsService
    @provider = OpenShift::NsupdatePlugin

    attr_reader :server, :port, :zone, :domain_suffix
    attr_reader :keyname, :keyvalue
    attr_reader :krb_principal, :krb_keytab

    # Establish the parameters for a connection to the DNS update service
    #
    # @param access_info [Hash] communication configuration settings
    # @see NsupdatePlugin NsupdatePlugin class Examples
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
      @krb_principal = access_info[:krb_principal]
      @krb_keytab = access_info[:krb_keytab]
      @zone = access_info[:zone]
    end

    private
    
    #
    # Generate an nsupdate add command string
    # 
    # @param fqdn [String] DNS record name to add
    # @param value [String] DNS record value
    # @return [String]
    #   An nsupdate command sequence
    def add_cmd(fqdn, value)

      # authenticate if credentials have been given
      if @krb_principal
        cmd = "kinit -kt #{@krb_keytab} #{@krb_principal} && \\\n"
        else
        cmd = ""
      end

      # If the config gave a TSIG key, use it
      keystring = @keyname ? "key #{@keyname} #{keyvalue}" : "gsstsig"

      # compose the nsupdate add command
      cmd += %{nsupdate <<EOF
#{keystring}
server #{@server} #{@port}
update add #{fqdn} 60 CNAME #{value}
send
quit
EOF
}


    end

    #
    # Generate an nsupdate delete command string
    # 
    # @param fqdn [String] DNS record name to delete
    # @return [String]
    #   An nsupdate command sequence
    def del_cmd(fqdn)
      # authenticate if credentials have been given
      if @krb_principal
        cmd = "kinit -kt #{@krb_keytab} #{@krb_principal} && \\\n"
        else
        cmd = ""
      end

      # If the config gave a TSIG key, use it
      keystring = @keyname ? "key #{@keyname} #{keyvalue}" : "gsstsig"

      # compose the nsupdate add command
      cmd += %{nsupdate <<EOF
#{keystring}
server #{@server} #{@port}
update delete #{fqdn}
send
quit
EOF
}
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
      
      cmd = add_cmd(fqdn, public_hostname)

      success = system cmd
      if not success
        raise DnsException.new("error adding app record #{fqdn}")
      end
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

      cmd = del_cmd(fqdn)
      # authenticate if credentials have been given
      if @krb_principal
        cmd = "kinit -kt #{@krb_keytab} #{@krb_principal} &&" + cmd
      end

      success = system cmd
      if not success
        raise DnsException.new("error deleting app record #{fqdn}")
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
