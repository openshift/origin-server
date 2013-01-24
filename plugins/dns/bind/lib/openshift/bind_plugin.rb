#
# Make OpenShift updates to a BIND DNS service
#
require 'rubygems'
require 'dnsruby'

module OpenShift
  class BindPlugin < OpenShift::DnsService
    @oo_dns_provider = OpenShift::BindPlugin

    # DEPENDENCIES
    # Rails.application.config.openshift[:domain_suffix]
    # Rails.application.config.dns[...]

    attr_reader :server, :port, :keyname, :keyvalue

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

    def dns
      if not @dns_con
        @dns_con = Dnsruby::Resolver.new(:nameserver => @server, :port => @port)
        @dns_con.src_port = @src_port if @src_port
      end
      @dns_con
    end

    def register_application(app_name, namespace, public_hostname)
      # create an A record for the application in the domain
      fqdn = "#{app_name}-#{namespace}.#{@domain_suffix}"
      # enable updates with key
      dns.tsig = @keyname, @keyvalue

      update = Dnsruby::Update.new(@zone)
      update.add(fqdn, 'CNAME', 60, public_hostname)
      dns.send_message(update)
    end

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
