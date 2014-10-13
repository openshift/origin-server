require 'openshift/routing/models/load_balancer'
require 'json'
require 'parseconfig'
require 'uri'
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

    # Send a PATCH request to the given URL with the given payload and
    # return the response.
    # patch :: Hash -> Net::HTTPResponse
    def patch options
      rest_request({ method: :patch }.merge(options))
    end

    # Send a DELETE request to the given URL and return the response.
    # delete :: Hash -> Net::HTTPResponse
    def delete options
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
             "monitor" => ("/Common/#{monitor_name}" if monitor_name),
             "name" => "#{pool_name}",
           }.to_json)
    end

    def delete_pool pool_name
      delete(url: "https://#{@host}/mgmt/tm/ltm/pool/#{pool_name}")
    end

    def get_route_names
      (JSON.parse(get(url: "https://#{@host}/mgmt/tm/ltm/policy/openshift_application_routes/rules")) || [])['items'].map {|item| item['name']}
    end

    alias_method :get_active_route_names, :get_route_names

    def create_route pool_name, route_name, path
      post(url: "https://#{@host}/mgmt/tm/ltm/policy/openshift_application_routes/rules",
           payload: {
             "kind" => "tm:ltm:policy:rules:rulesstate",
             "name" => route_name,
           }.to_json)
      post(url: "https://#{@host}/mgmt/tm/ltm/policy/openshift_application_routes/rules/#{route_name}/conditions",
           payload: {
             "kind" => "tm:ltm:policy:rules:actions:conditionsstate",
             "name" => "0",
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
      post(url: "https://#{@host}/mgmt/tm/ltm/policy/openshift_application_routes/rules/#{route_name}/actions",
           payload: {
             "kind" => "tm:ltm:policy:rules:actions:actionsstate",
             "name" => "0",
             "code" => 0,
             "forward" => true,
             "pool" => "/Common/#{pool_name}",
             "port" => 0,
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
      delete(url: "https://#{@host}/mgmt/tm/ltm/policy/openshift_application_routes/rules/#{route_name}")
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
      member = address + ':' + port.to_s
      post(url: "https://#{@host}/mgmt/tm/ltm/pool/#{pool_name}/members",
            payload: {
                "kind" => "ltm:pool:members",
                "name" => member,
            }.to_json)
    end

    def delete_pool_member pool_name, address, port
      delete(url: "https://#{@host}/mgmt/tm/ltm/pool/#{pool_name}/members/#{address + ':' + port.to_s}")
    end

    def get_pool_aliases pool_name
      alias_name_regex = Regexp.new("\\Aalias_#{pool_name}_(.*)\\Z")
      (JSON.parse(get(url: "https://#{@host}/mgmt/tm/ltm/policy/openshift_application_aliases/rules")) || [])['items'].map {|item| item['name']}.grep(alias_name_regex) {$1}
    end

    def add_pool_alias pool_name, alias_str
      alias_name = "alias_#{URI.escape(pool_name)}_#{URI.escape(alias_str)}"
      post(url: "https://#{@host}/mgmt/tm/ltm/policy/openshift_application_aliases/rules",
           payload: {
             "kind" => "tm:ltm:policy:rules:rulesstate",
             "name" => alias_name,
           }.to_json)
      post(url: "https://#{@host}/mgmt/tm/ltm/policy/openshift_application_aliases/rules/#{alias_name}/conditions",
           payload: {
             "kind" => "tm:ltm:policy:rules:actions:conditionsstate",
             "name" => "0",
             "caseInsensitive" => true,
             "external" => true,
             "httpHost" => true,
             "index" => 0,
             "equals" => true,
             "present" => true,
             "remote" => true,
             "request" => true,
             "values" => [alias_str]
           }.to_json)
      post(url: "https://#{@host}/mgmt/tm/ltm/policy/openshift_application_aliases/rules/#{alias_name}/actions",
           payload: {
             "kind" => "tm:ltm:policy:rules:actions:actionsstate",
             "name" => "0",
             "code" => 0,
             "forward" => true,
             "pool" => "/Common/#{pool_name}",
             "port" => 0,
             "request" => true,
             "select" => true,
             "status" => 0,
             "vlanId" => 0,
           }.to_json)
    end

    def delete_pool_alias pool_name, alias_str
      alias_name = "alias_#{URI.escape(pool_name)}_#{URI.escape(alias_str)}"
      delete(url: "https://#{@host}/mgmt/tm/ltm/policy/openshift_application_aliases/rules/#{alias_name}")
    end

    def initialize logger, cfgfile
      @logger = logger

      @logger.info 'Initializing F5 iControl REST interface model...'

      read_config cfgfile

      # Create the openshift_application_routes an openshift_application_aliases
      # policies if they do not already exist.  The create_route and
      # delete_route methods add and delete the application-specific rules to
      # and from the former, and the add_pool_alias and delete_pool_alias
      # methods add and delete the application-specific rules to and from the
      # latter.
      ["openshift_application_routes","openshift_application_aliases"].each do |policy|
        begin
          get(url: "https://#{@host}/mgmt/tm/ltm/policy/#{policy}")
        rescue RestClient::ResourceNotFound
          @logger.info "No #{policy} policy exists.  Creating..."
          post(url: "https://#{@host}/mgmt/tm/ltm/policy",
               payload: {
                 "kind" => "tm:ltm:policy:policystate",
                 "name" => policy,
                 "controls" => ["forwarding"],
                 "requires" => ["http"],
                 "strategy" => "first-match",
               }.to_json)
        end
      end
    end

  end

end
