#
# Make Openshift
#
require 'rubygems'

module OpenShift

  # 
  class NsupdatePlugin < OpenShift::DnsService
    @provider = OpenShift::NsupdatePlugin

    attr_reader :server, :port, :keyname, :keyvalue

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

    def modify_application(app_name, namespace, public_hostname)
      deregister_application(app_name, namespace)
      register_application(app_name, namespace, public_hostname)
    end

    def publish
    end

    def close
    end

  end
end
