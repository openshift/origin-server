require 'rubygems'
require 'httpclient'

module OpenShift
  class AvahiPlugin < OpenShift::DnsService
    @provider = OpenShift::AvahiPlugin
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
      body = { 
        'cname' => "#{app_name}-#{namespace}.#{@zone}", 
        'fqdn' => public_hostname,
        'key_name' => @keyname,
        'key_value' => @keyvalue,
      }
      Rails.logger.debug "Posting update #{body.inspect} to http://#{@server}:#{@port}/add_alias"
      clnt = HTTPClient.new
      res = clnt.post("http://#{@server}:#{@port}/add_alias", body)
      Rails.logger.debug "response: #{res.status}"
      raise DNSException.new(res.body) unless res.status == 200
    end

    def deregister_application(app_name, namespace)
      body = { 
        'cname' => "#{app_name}-#{namespace}.#{@zone}", 
        'key_name' => @keyname,
        'key_value' => @keyvalue,
      }
      Rails.logger.debug "Posting update #{body.inspect} to http://#{@server}:#{@port}/remove_alias"
      clnt = HTTPClient.new
      res = clnt.post("http://#{@server}:#{@port}/remove_alias", body)
      Rails.logger.debug "response: #{res.status}"
      raise DNSException.new(res.body) unless res.status == 200
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
