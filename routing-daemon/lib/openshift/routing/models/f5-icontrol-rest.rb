require 'openshift/routing/models/load_balancer'
require 'json'
require 'parseconfig'
require 'restclient'

module OpenShift

  # == Load-balancer model class for the F5 BIG-IP LTM load balancer.
  #
  # Presents direct access to an F5 BIG-IP LTM load balancer using the
  # iControl REST interface.
  #
  class F5IControlRestLoadBalancerModel < LoadBalancerModel

    def read_config cfgfile
      cfg = ParseConfig.new(cfgfile)

      @host = cfg['BIGIP_HOST'] || '127.0.0.1'
      @username = cfg['BIGIP_USERNAME'] || 'admin'
      @password = cfg['BIGIP_PASSWORD'] || 'passwd'
    end

    # Send a REST request to the given URL and return the response.
    # rest_request :: Hash -> Net::HTTPResponse
    def rest_request options
      defaults = {
        headers: { :content_type => :json },
        timeout: @timeout,
        open_timeout: @open_timeout,
        user: @username,
        password: @password,
      }

      expected_code = options.delete(:expected_code) || 200

      RestClient::Request.execute(defaults.merge(options)).tap do |response|
        unless response.code == expected_code
          raise LBModelException.new "Expected HTTP #{expected_code} but got #{response.code} instead"
        end
      end
    end

    # Send a GET request to the given URL and return the response.
    # get :: String -> Net::HTTPResponse
    def get options
      rest_request({ method: :get }.merge(options))
    end

    # Send a POST request to the given URL with the given payload and
    # return the response.
    # post :: Hash -> Net::HTTPResponse
    def post options
      rest_request({ method: :post }.merge(options))
    end

    # Send a PUT request to the given URL with the given payload and
    # return the response.
    # put :: Hash -> Net::HTTPResponse
    def put options
      rest_request({ method: :put }.merge(options))
    end

    # Send a DELETE request to the given URL and return the response.
    # put :: Hash -> Net::HTTPResponse
    def put options
      rest_request({ method: :delete }.merge(options))
    end

    # Returns [String] of pool names.
    def get_pool_names
      (JSON.parse(get(url: "https://#{@host}/mgmt/tm/ltm/pool"))['items'] || []).map {|item| item['name']}
    end

    def create_pool pool_name, monitor_name
      post(url: "https://#{@host}/mgmt/tm/ltm/pool",
           payload: {
             "loadBalancingMode" => "round-robin",
             "monitor" => "/Common/#{monitor_name}",
             "name" => "#{pool_name}",
           }.to_json)
    end

    def delete_pool pool_name
      delete(url: "https://#{@host}/mgmt/tm/ltm/pool/#{pool_name}")
    end

    def get_route_names
      (JSON.parse(get(url: "https://#{@host}/mgmt/tm/ltm/policy")) || [])['items'].map {|item| item['name']}
    end

    def get_active_route_names
      (JSON.parse(get(url: "https://#{@host}/mgmt/tm/ltm/virtual/~Common~ose-vlan/policies")) || [])['items'].map {|item| item['name']}
    end

    def create_route pool_name, route_name, path
      post(url: "https://#{@host}/mgmt/tm/ltm/policy/openshift_applications/rules/#{route_name}",
           payload: {
             "controls" => ["forwarding"],
             "requires" => ["http"],
             "strategy" => "/Common/first-match",
           }.to_json)
      post(url: "https://#{@host}/mgmt/tm/ltm/policy/openshift_applications/rules/#{route_name}/conditions/0",
           payload: {
             "caseInsensitive" => true,
             "external" => true,
             "httpUri" => true,
             "index" => 0,
             "path" => true,
             "present" => true,
             "remote" => true,
             "request" => true,
             "startsWith" => true,
             "values" => [path]
           }.to_json)
      post(url: "https://#{@host}/mgmt/tm/ltm/policy/openshift_applications/rules/#{route_name}/actions/0",
           payload: {
             "code" => 0,
             "forward" => true,
             "pool" => "/Common/#{pool_name}",
             "port" => 80,
             "request" => true,
             "select" => true,
             "status" => 0,
             "vlanId" => 0,
           }.to_json)
    end

    def attach_routes route_names, virtual_server_names
      # no-op
    end

    def detach_routes route_names, virtual_server_names
      # no-op
    end

    def delete_route pool_name, route_name
      delete(url: "https://#{@host}/mgmt/tm/ltm/policy/openshift_applications/rules/#{route_name}")
    end

    def get_monitor_names
      (JSON.parse(get(url: "https://#{@host}/mgmt/tm/ltm/monitor/http")) || [])['items'].map {|item| item['name']} + \
        (JSON.parse(get(url: "https://#{@host}/mgmt/tm/ltm/monitor/https")) || [])['items'].map {|item| item['name']}
    end

    def create_monitor monitor_name, path, up_code, type, interval, timeout
      type = type == 'https-ecv' ? 'https' : 'http'
      post(url: "https://#{@host}/mgmt/tm/ltm/monitor/#{type}/#{monitor_name}",
           payload: {
             "interval" => interval,
             "recv" => up_code,
             "send" => "HEAD #{path} HTTP/1.0\\r\\n\\r\\n",
             "timeout" => timeout,
             "upInterval" => interval,
           })
    end

    def delete_monitor monitor_name
      # TODO: delete_monitor needs a 'type' parameter for the REST API.
      delete(url: "https://#{@host}/mgmt/tm/ltm/monitor/http/#{monitor_name}")
      #delete(url: "https://#{@host}/mgmt/tm/ltm/monitor/#{type}/#{monitor_name}")
    end

    def get_pool_members pool_name
      JSON.parse(get(url: "https://#{@host}/mgmt/tm/ltm/pool/#{pool_name}/members"))['items'].map {|item| item['name']}
    end

    alias_method :get_active_pool_members, :get_pool_members

    def add_pool_member pool_name, address, port
      post(url: "https://#{@host}/mgmt/tm/ltm/pool/#{pool_name}/members/#{address + ':' + port.to_s}")
    end

    def delete_pool_member pool_name, address, port
      delete(url: "https://#{@host}/mgmt/tm/ltm/pool/#{pool_name}/members/#{address + ':' + port.to_s}")
    end

    def initialize logger, cfgfile
      @logger = logger

      @logger.info 'Initializing F5 iControl REST interface model...'

      read_config cfgfile

      # TODO: Create the openshift_applications policy if it does not
      # already exist.  The create_route and delete_route methods add
      # the application-specific rules to this policy.
      #post(url: "https://#{@host}/mgmt/tm/ltm/policy/openshift_applications",
      #     payload: {
      #       "controls" => ["forwarding"],
      #       "requires" => ["http"],
      #       "strategy" => "/Common/first-match",
      #     }.to_json)
    end

  end

end
