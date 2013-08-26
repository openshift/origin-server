#
# OpenShift DNS update plugin for Infoblox DNS service
#
require 'rubygems'
require 'json'
require 'rest-client'

module OpenShift

  # OpenShift DNS plugin to provide dynamic DNS using the 
  # {http://www.infoblox Infoblox(r)} service via the
  # {http://www.infoblox.com/community/content/getting-started-infoblox-web-api-wapi Infoblox Web API (WAPI)}
  #
  # Implements the OpenShift::DnsService interface
  #
  # This class uses the {https://rubygems.org/gems/rest-client rest-client} 
  # rubygem to communicate with the Infoblox service.
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
  # @example infoblox plugin configuration hash
  #  {:infoblox_server => 'infobloxserver',
  #   :infoblox_username => 'infobloxuser',
  #   :infoblox_password => 'infobloxsecret',
  #  }
  #
  # @!attribute [r] server
  #   @return [String] Hostname or IP address of the Infoblox server
  # @!attribute [r] username
  #   @return [String] user name to be used for update authentication
  # @!attribute [r] password
  #   @return [String] password to be used to authenticate the update user
  class InfobloxPlugin < OpenShift::DnsService
    @oo_dns_provider = OpenShift::InfobloxPlugin

    attr_reader :server, :username, :password, :ttl
    attr_reader :record_type, :base_url

    # Establish the parameters for a connection to the DNS update service
    #
    # @param access_info [Hash] communication configuration settings
    # @see InfobloxPlugin InfobloxPlugin class Examples
    def initialize(access_info = nil)

      if access_info != nil
        @domain_suffix = access_info[:domain_suffix]
      elsif defined? Rails
        access_info = Rails.application.config.dns
        @domain_suffix = Rails.application.config.openshift[:domain_suffix]
      else
        raise Exception.new("Infoblox DNS service is not initialized")
      end

      @server = access_info[:infoblox_server]
      @username = access_info[:infoblox_username]
      @password = access_info[:infoblox_password]
      @ttl = access_info[:ttl] == nil ? 30 : access_info[:ttl].to_i

      @api_path = 'wapi'
      @api_version = '1.1'
      @record_type = 'cname'

      # Construct the base URL for update queries
      @base_url = "https://#{@username}:#{@password}@#{@server}/" +
        "#{@api_path}/v#{@api_version}/" 

      @record_url = @base_url + "record:#{@record_type}"
      
      # attempt to connect to the Infoblox service and request the SOA record
      # for the application update zone
      zone_record_string = execute(RestClient.method(:get),
                                   @base_url + "zone_auth",
                                   nil,
                                   { :fqdn => @domain_suffix })


      if ([nil, '', '[]'].member? zone_record_string)
        raise DNSException.new("Infoblox DNS service does not control zone: #{@domain_suffix}")
      end

      zone_record = JSON.parse(zone_record_string)

  
      # check that the zone is there?
      #zones = JSON.parse(zone_result_string)
  
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
      # in this case, public_hostname is the hostname of the node the
      # application is running on

      # create a cname record for the application in the domain
      fqdn = "#{app_name}-#{namespace}.#{@domain_suffix}"

      # build the json data to submit to create the cname record
      data_to_send = {'canonical' => public_hostname, 'name' => fqdn}

      res = execute(RestClient.method(:post), @record_url, data_to_send)

      #if not success
      if res == nil
        raise DNSException.new("error adding app record #{fqdn}")
      end
      res

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

      # build the fqdn string for the application
      fqdn = "#{app_name}-#{namespace}.#{@domain_suffix}"

      # we need to get the infoblox id for the record we wish to delete
      record_id = get_record_id(fqdn)
    
      res = execute(RestClient.method(:delete), @base_url + record_id)

      #if not success
      if res == nil
        raise DNSException.new("error adding app record #{fqdn}")
      end
      res

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
    def modify_application(app_name, namespace, new_public_hostname)
      # modify the CNAME record for the application in the domain

      # build the fqdn string for the application
      fqdn = "#{app_name}-#{namespace}.#{@domain_suffix}"

      # we need to get the infoblox id for the record we wish to modify
      record_id = get_record_id(fqdn)
    
      # build the json data to submit to modify the cname record
      data_to_send = {'canonical' => new_public_hostname, 'name' => fqdn}

      res = execute(RestClient.method(:put), @base_url + record_id, data_to_send)

      #if not success
      if res == nil
        raise DNSException.new("error adding app record #{fqdn}")
      end
      res

    end

    # get a DNS record id string from the Infoblox service
    #
    # @param [String] fqdn
    #   The fully qualified domain name of the record to query
    # @return [String]
    #   The Infoblox record ID string for the requested record
    def get_record_id(fqdn)

      res = execute(RestClient.method(:get), @record_url, nil, {:name => fqdn})

      return nil if res == nil

      # Can return uncaught ArgumentError ('') or TypeError (nil)
      res = JSON.parse(res)

      return nil if (not res or res.length == 0)
      res[0]["_ref"]

    end

    # placeholder for possible bulk update behavior
    def publish

    end

    # placeholder for possible persistant connection behavior
    def close

    end

    private

    def execute(rest_function, resource_url, data=nil, params=nil)
      begin
        if not data == nil
          result_string = rest_function.call(resource_url, data,
                                             :params => params,
                                             :accept => :json
                                           )
        else
          result_string = rest_function.call(resource_url,
                                            :params => params,
                                             :accept => :json)
        end

      rescue Errno::EHOSTUNREACH => e
        raise DNSException.new("unable to reach Infoblox server: #{@server}\n#{e}")

      rescue SocketError => e
        raise DNSException.new("unknown Infoblox server: #{@server}\n#{e}")

      rescue RestClient::Unauthorized => e
        raise DNSException.new("Infoblox service authentication failed: server: #{@server}, username: #{@username}\n#{e}")
        
      rescue RestClient::BadRequest => e
        raise DNSException.new("unknown REST request error: fqdn=#{@domain_suffix}\nresource: #{resource_url}\ndata: #{data}\n#{e}")
      
      end

      result_string
    end

  end
end
