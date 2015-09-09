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
      @https_vserver = cfg['VIRTUAL_HTTPS_SERVER'] || 'https-ose-vserver'
      @vserver = cfg['VIRTUAL_SERVER'] || 'ose-vserver'
      @ssh_private_key = cfg['BIGIP_SSHKEY'] || '/etc/openshift/bigip.key'
      @device_group = cfg['BIGIP_DEVICE_GROUP']
    end

    def run cmd
      # Using exec 2>&1 ensures that we redirect any error output from /bin/sh
      # (such as syntax errors in the command) in addition to any error output
      # from the command itself.
      output = `exec 2>&1; #{cmd}`

      if $?.exitstatus != 0
        raise LBModelException.new "Command `#{cmd}`" \
          " returned exit code #{$?.exitstatus}, output: #{output}"
      end
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
        wrap_exceptions: true,
      }

      expected_code = options.delete(:expected_code) || 200

      options.merge!(defaults) {|_,option,default| option}

      begin
        RestClient::Request.execute(options).tap do |response|
          unless response.code == expected_code
            raise LBModelException.new "Expected HTTP #{expected_code} but got #{response.code} instead"
          end
        end
      rescue => e
        raise unless options.wrap_exceptions

        msg = "got #{e.class} exception: #{e.message}"
        begin
          resp = JSON.parse e.response
          m = resp['message']
          msg += " (#{m})" unless m.empty?
        rescue
        end

        raise LBModelException.new msg
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

    def get_monitor_names
      (JSON.parse(get(url: "https://#{@host}/mgmt/tm/ltm/monitor/http")) || [])['items'].map {|item| item['name']} + \
        (JSON.parse(get(url: "https://#{@host}/mgmt/tm/ltm/monitor/https")) || [])['items'].map {|item| item['name']}
    end

    def create_monitor monitor_name, path, up_code, type, interval, timeout
      type = type == 'https-ecv' ? 'https' : 'http'
      post(url: "https://#{@host}/mgmt/tm/ltm/monitor/#{type}",
           payload: {
             "name" => monitor_name,
             "interval" => interval,
             "recv" => up_code,
             "send" => "HEAD #{path} HTTP/1.0\\r\\n\\r\\n",
             "timeout" => timeout,
             "upInterval" => interval,
           }.to_json)
    end

    def delete_monitor monitor_name, type
      type = type == 'https-ecv' ? 'https' : 'http'
      delete(url: "https://#{@host}/mgmt/tm/ltm/monitor/#{type}/#{monitor_name}")
    end

    # add_pool_monitor :: String, String -> undefined
    def add_pool_monitor pool_name, monitor_name
      monitor_name = "/Common/#{monitor_name}" unless monitor_name =~ /^\/Common\//
      monitors = get_pool_monitors(pool_name).
        push(monitor_name).
        map {|m| m+' '}.
        join('and ')
      patch(url: "https://#{@host}/mgmt/tm/ltm/pool/#{pool_name}",
            payload: {
              "monitor" => monitors,
            }.to_json)
    end

    # delete_pool_monitor :: String, String -> undefined
    def delete_pool_monitor pool_name, monitor_name
      monitor_name = "/Common/#{monitor_name}" unless monitor_name =~ /^\/Common\//
      monitors = get_pool_monitors(pool_name).
        tap {|ary| ary.delete(monitor_name)}.
        map {|m| m+' '}.
        join('and ')
      patch(url: "https://#{@host}/mgmt/tm/ltm/pool/#{pool_name}",
            payload: {
              "monitor" => monitors,
            }.to_json)
    end

    def get_pool_monitors pool_name
      pool_json = get(url: "https://#{@host}/mgmt/tm/ltm/pool/#{pool_name}")
      # The JSON representation of a pool uses a string rather than an array
      # to represent the list of monitors.  A single monitor is represented as
      # '/Common/foo ' (with the trailing whitespace), two monitors are
      # represented as '/Common/foo and /Common/bar ', three monitors as
      # '/Common/foo and /Common/bar and /Common/baz ', and so on.
      JSON.parse(pool_json)['monitor'].split('and ').map {|m| m.chomp ' '} rescue []
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

    def add_ssl pool_name, alias_str, ssl_cert, private_key
      # The LTM must be configured with a default client SSL profile for
      # fallback for custom alias SSL to work with SNI.
      # https://support.f5.com/kb/en-us/solutions/public/13000/400/sol13452.html

      begin
        # write temp cert and key
        certfile = Tempfile.new('bigip-ssl-cert')
        keyfile = Tempfile.new('bigip-ssl-key')

        certfile.write(ssl_cert)
        certfile.close
        keyfile.write(private_key)
        keyfile.close

        sshflags = "-o StrictHostKeyChecking=no -o PasswordAuthentication=no" \
          " -o VerifyHostKeyDNS=no -o UserKnownHostsFile=/dev/null" \
          " -i \"#{@ssh_private_key}\""

        # scp cert and key to F5 LTM (requires ssh key to be in authorized_keys on the F5 LTM).
        @logger.debug("Copying certificate for alias #{alias_str} for pool #{pool_name} to LTM host")
        run("scp #{sshflags} #{certfile.path} #{@username}@#{@host}:/var/tmp/#{alias_str}.crt")

        @logger.debug("Copying key for alias #{alias_str} for pool #{pool_name} to LTM host")
        run("scp #{sshflags} #{keyfile.path} #{@username}@#{@host}:/var/tmp/#{alias_str}.key")

        @logger.debug("LTM cert to be installed /var/tmp/#{alias_str}.crt")
        post(url: "https://#{@host}/mgmt/tm/sys/crypto/cert",
               payload: {
                 "command" => "install",
                 "name" => "#{alias_str}-https-cert",
                 "from-local-file" => "/var/tmp/#{alias_str}.crt"
               }.to_json)

        @logger.debug("LTM cert to be installed /var/tmp/#{alias_str}.key")
        post(url: "https://#{@host}/mgmt/tm/sys/crypto/key",
               payload: {
                 "command" => "install",
                 "name" => "#{alias_str}-https-key",
                 "from-local-file" => "/var/tmp/#{alias_str}.key"
               }.to_json)

        @logger.debug("LTM creating client-ssl profile for  #{alias_str}")
        post(url: "https://#{@host}/mgmt/tm/ltm/profile/client-ssl",
                 payload: {
                   "name" => "#{alias_str}-ssl-profile",
                   "cert" => "#{alias_str}-https-cert.crt",
                   "key" => "#{alias_str}-https-key.key",
                   "serverName" => "#{alias_str}"
                 }.to_json)

        @logger.debug("LTM adding #{alias_str}-ssl-profile client-ssl to #{@https_vserver}")
        post(url: "https://#{@host}/mgmt/tm/ltm/virtual/#{@https_vserver}/profiles",
                 payload: {
                   "name" => "#{alias_str}-ssl-profile",
                   "context" => "clientside",
                 }.to_json)

        # Requires LTM System->Users->admin terminal setting to be set to advanced (bash)
        @logger.debug("LTM removing temporary alias certificate")
        run("ssh #{sshflags} #{@username}@#{@host} 'rm -f /var/tmp/#{alias_str}.crt'")

        @logger.debug("LTM removing temporary alias key")
        run("ssh #{sshflags} #{@username}@#{@host} 'rm -f /var/tmp/#{alias_str}.key'")
      rescue Errno::ENOENT
        # Nothing to do;
      ensure
        certfile.unlink
        keyfile.unlink
      end
    end

    def remove_ssl pool_name, alias_str
      @logger.debug("LTM removing #{URI.escape(alias_str)}-ssl-profile client-ssl from #{@https_vserver}")
      delete(url: "https://#{@host}/mgmt/tm/ltm/virtual/#{@https_vserver}/profiles/#{URI.escape(alias_str)}-ssl-profile")

      @logger.debug("LTM deleting removing #{URI.escape(alias_str)}-ssl-profile")
      delete(url: "https://#{@host}/mgmt/tm/ltm/profile/client-ssl/#{URI.escape(alias_str)}-ssl-profile")

      @logger.debug("LTM removing #{alias_str}-https-key")
      delete(url: "https://#{@host}/mgmt/tm/sys/file/ssl-key/#{URI.escape(alias_str)}-https-key.key")

      @logger.debug("LTM removing #{alias_str}-https-cert")
      delete(url: "https://#{@host}/mgmt/tm/sys/file/ssl-cert/#{URI.escape(alias_str)}-https-cert.crt")
    end

    def get_pool_certificates pool_name
      pool_certs = []
      return pool_certs
    end

    def update
      post(url: "https://#{@host}/mgmt/tm/cm",
           payload: {
             "command" => "run",
             "utilCmdArgs" => "config-sync to-group #{@device_group}",
           }.to_json) unless @device_group.nil? || @device_group.empty?
    end

    def initialize logger, cfgfile
      @logger = logger

      @logger.info 'Initializing F5 iControl REST interface model...'

      read_config cfgfile

      # Create the openshift_application_aliases policy if it does not already
      # exist. The add_pool_alias and delete_pool_alias methods add and delete
      # the application-specific rules to and from the latter.
      policy = 'openshift_application_aliases'
      begin
        get(url: "https://#{@host}/mgmt/tm/ltm/policy/#{policy}",
            wrap_exceptions: false)
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

        # Create a noop rule for the policy so we can add the policy to the vservers
        post(url: "https://#{@host}/mgmt/tm/ltm/policy/#{policy}/rules",
         payload: {
           "kind" => "tm:ltm:policy:rules:rulesstate",
           "name" => "default_noop",
         }.to_json)

        # Now add the policy to the virtual servers
        post(url: "https://#{@host}/mgmt/tm/ltm/virtual/#{@vserver}/policies",
             payload: {
               "name" => policy
             }.to_json)

        post(url: "https://#{@host}/mgmt/tm/ltm/virtual/#{@https_vserver}/policies",
             payload: {
               "name" => policy
             }.to_json)
      end
    end

  end

end
