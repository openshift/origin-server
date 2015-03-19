require 'parseconfig'
require 'time'
require 'openshift/routing/models/load_balancer'

module OpenShift

  # == Load-balancer model class for an LBaaS load balancer.
  #
  # Presents direct access to a load balancer using the LBaaS REST API.
  #
  # This class contains minimal logic and no error checking; its sole
  # purpose is to hide REST calls behind a more convenient interface.
  class LBaaSLoadBalancerModel < LoadBalancerModel

    def read_config cfgfile
      cfg = ParseConfig.new(cfgfile)

      @host = cfg['LBAAS_HOST'] || '127.0.0.1'
      @tenant = cfg['LBAAS_TENANT'] || 'openshift'
      @timeout = cfg['LBAAS_TIMEOUT'] || '60'
      @open_timeout = cfg['LBAAS_OPEN_TIMEOUT'] || '30'
      @keystone_host = cfg['LBAAS_KEYSTONE_HOST'] || @lbaas_host
      @keystone_username = cfg['LBAAS_KEYSTONE_USERNAME'] || 'admin'
      @keystone_password = cfg['LBAAS_KEYSTONE_PASSWORD'] || 'passwd'
      @keystone_tenant = cfg['LBAAS_KEYSTONE_TENANT'] || 'lbms'
    end

    # Get the standard HTTP headers for LBaaS REST call.
    # lbaas_headers :: String
    def lbaas_headers
      ret = {
        :content_type => :json,
        :accept => :json,
      }

      ret[:'X-Auth-Token'] = @keystone_token if @keystone_token

      ret
    end

    # Send a GET request to the given URL and return the response.
    # get :: String -> Net::HTTPResponse
    def get url
      RestClient::Request.execute(:method => :get, :url => url, :headers => lbaas_headers, :timeout => @timeout, :open_timeout => @open_timeout)
    end

    # Send a POST request to the given URL with the given payload and
    # return the response.
    # post :: String, String -> Net::HTTPResponse
    def post url, payload
      RestClient::Request.execute(:method => :post, :url => url, :payload => payload, :headers => lbaas_headers, :timeout => @timeout, :open_timeout => @open_timeout)
    end

    # Send a PUT request to the given URL with the given payload and
    # return the response.
    # put :: String, String -> Net::HTTPResponse
    def put url, payload
      RestClient::Request.execute(:method => :put, :url => url, :payload => payload, :headers => lbaas_headers, :timeout => @timeout, :open_timeout => @open_timeout)
    end

    # Parses the response from a RestClient request to LBaaS and returns an
    # array of job ids.
    # String -> [String]
    def parse_jobids response
      begin
        JSON.parse(response)['Lb_Job_List']['jobIds']
      rescue => e
        @logger.warn "Got exception parsing response: #{e.message}"
        @logger.debug "Backtrace:\n#{e.backtrace.join "\n"}"
        @logger.debug "Response:\n#{response}"
        []
      end
    end

    def get_pool_certificates pool_name
      @logger.debug "get pool certificates #{pool_name}"
      [] # Return an array of String representing certificates.
    end

   # Returns [String] of pool names.
    def get_pool_names
      JSON.parse(get("http://#{@host}/loadbalancers/tenant/#{@tenant}/pools"))['tenantpools']['pools']
    end

    # Returns [String] of job ids.
    def create_pool pool_name, monitor_name=nil
      monitor_name ||= 'http'

      response = put("http://#{@host}/loadbalancers/tenant/#{@tenant}/pools/#{pool_name}",
                     {
                       :pool => {
                         :name => pool_name,
                         :method => 'RoundRobin',
                         :port => '80',
                         :enabled => 'true',
                         :monitors => [monitor_name]
                       }
                     }.to_json)
      raise LBModelException.new "Expected HTTP 202 but got #{response.code} instead" unless response.code == 202

      parse_jobids response
    end

    # Returns [String] of job ids.
    def delete_pool pool_name
      response = RestClient.delete("http://#{@host}/loadbalancers/tenant/#{@tenant}/pools/#{pool_name}",
                                   :content_type => :json,
                                   :accept => :json,
                                   :'X-Auth-Token' => @keystone_token)
      raise LBModelException.new "Expected HTTP 202 but got #{response.code} instead" unless response.code == 202

      parse_jobids response
    end

    # Returns [String] of monitor names.
    def get_monitor_names
      (JSON.parse(get("http://#{@host}/loadbalancers/tenant/#{@tenant}/monitors/"))['monitor'] || []).map {|m| m['name']}
    end

    # Returns [String] of job ids.
    def create_monitor monitor_name, path, up_code, type, interval, timeout
      type = type == 'https-ecv' ? 'HTTPS' : 'HTTP-ECV'
      response = put("http://#{@host}/loadbalancers/tenant/#{@tenant}/monitors/#{monitor_name}",
                     {
                       :monitor => {
                         :name => monitor_name,
                         :type => type,
                         :send => "GET #{path}",
                         :rcv => up_code,
                         :interval => interval,
                         :timeout => timeout,
                         :downtime => '12'
                       }
                     }.to_json)
      raise LBModelException.new "Expected HTTP 202 but got #{response.code} instead" unless response.code == 202

      parse_jobids response
    end

    # Returns [String] of job ids.
    def delete_monitor monitor_name, type
      response = RestClient.delete("http://#{@host}/loadbalancers/tenant/#{@tenant}/monitors/#{monitor_name}",
                                   :content_type => :json,
                                   :accept => :json,
                                   :'X-Auth-Token' => @keystone_token)
      raise LBModelException.new "Expected HTTP 202 but got #{response.code} instead" unless response.code == 202

      parse_jobids response
    end

    def add_pool_monitor pool_name, monitor_name
    end

    def delete_pool_monitor pool_name, monitor_name
    end

    def get_pool_monitors pool_name
    end

    # Returns [String] of pool names.
    def get_pool_members pool_name
      begin
        (JSON.parse(get("http://#{@host}/loadbalancers/tenant/#{@tenant}/pools/#{pool_name}"))['pool']['services'] || []).map {|p| p['name']}
      rescue => e
        @logger.warn "Got exception while getting pool members: #{e.message}"
        @logger.debug "Backtrace:\n#{e.backtrace.join "\n"}"
        []
      end
    end

    alias_method :get_active_pool_members, :get_pool_members

    # Returns [String] of job ids.
    def add_pool_members pool_names, member_lists
      response = post("http://#{@host}/loadbalancers/tenant/#{@tenant}/pools",
                      {
                        :pool =>
                          (pool_names.zip member_lists).map do |pool_name, members| {
                            :services => members.map do |address,port| {
                              :ip => address,
                              :enabled => 'true',
                              :name => address + ':' + port.to_s,
                              :weight => "10",
                              :port => port
                            } end,
                            :name => pool_name
                          } end
                      }.to_json)
      raise LBModelException.new "Expected HTTP 202 but got #{response.code} instead" unless response.code == 202

      parse_jobids response
    end

    # Returns [String] of job ids.
    def delete_pool_member pool_name, address, port
      response = RestClient.delete("http://#{@host}/loadbalancers/tenant/#{@tenant}/pools/#{pool_name}/services/#{address + '%3a' + port.to_s}",
                                   :content_type => :json,
                                   :accept => :json,
                                   :'X-Auth-Token' => @keystone_token)
      case response.code
      when 202
        parse_jobids response
      when 204
        []
      else
        raise LBModelException.new "Expected HTTP 202 or 204 but got #{response.code} instead"
      end
    end

    def add_ssl pool_name, alias_str, ssl_cert, private_key
      # no-opp
    end

    def remove_ssl pool_name, alias_str
      # no-op
    end

    # Returns Hash representing the JSON response from the load balancer.
    def get_job_status id
      response = get "http://#{@host}/loadbalancers/tenant/#{@tenant}/jobs/#{id}"
      raise LBModelException.new "Expected HTTP 200 but got #{response.code} instead" unless response.code == 200

      JSON.parse(response)
    end

    # Re-authenticate if the token will expire within a period equal
    # to twice the timeout.
    def maybe_reauthenticate
      if @keystone_token_expiration < Time.now + 2*@timeout
        @logger.info "Permanent token will expire soon.  Re-authenticating..."
        authenticate
      end
    end

    # Returns String representing the keystone token and sets @keystone_token to
    # the same.  This method must be called before the others, which use
    # @keystone_token.
    def authenticate
      # Be sure not to have a token saved so as not to send it when
      # requesting the temporary token.
      @keystone_token = nil

      @logger.info "Requesting temporary token from keystone..."
      response = post("http://#{@keystone_host}/v2.0/tokens",
                      {
                        :auth => {
                          :passwordCredentials => {
                            :username => @keystone_username,
                            :password => @keystone_password
                          }
                        }
                      }.to_json)
      raise LBModelException.new "Expected HTTP 200 but got #{response.code} instead" unless response.code == 200

      @keystone_token = JSON.parse(response)['access']['token']['id']
      @logger.info "Got temporary token: #{@keystone_token}"

      @logger.info "Requesting list of keystone tenants..."
      response = get "http://#{@keystone_host}/v2.0/tenants"
      raise LBModelException.new "Expected HTTP 200 but got #{response.code} instead" unless response.code == 200

      tenants = JSON.parse(response)['tenants'] or raise LBModelException.new "Error getting list of tenants from keystone"
      tenant = tenants.find {|t| t['name'] == @keystone_tenant} or raise LBModelException.new "Keystone tenant not found: #{@keystone_tenant}"
      tenant_id = tenant['id'] or raise LBModelException.new "Could not find tenantId for keystone tenant: #{@keystone_tenant}"

      @logger.info "Requesting permanent token from keystone..."
      response = post("http://#{@keystone_host}/v2.0/tokens",
                      {
                        :auth => {
                          :project => 'lbms',
                          :passwordCredentials => {
                            :username => @keystone_username,
                            :password => @keystone_password
                          },
                          :tenantId => tenant_id
                        }
                      }.to_json)
      raise LBModelException.new "Expected HTTP 200 but got #{response.code} instead" unless response.code == 200

      @keystone_token = JSON.parse(response)['access']['token']['id']
      @keystone_token_expiration = Time.parse JSON.parse(response)['access']['token']['expires']
      @logger.info "Got permanent token: #{@keystone_token} with expiration #{@keystone_token_expiration.to_s}"
      @keystone_token
    end

    def initialize logger, cfgfile
      @logger = logger

      @logger.info 'Initializing LBaaS model...'

      read_config cfgfile
    end

  end

end
