require 'active_support'
require $dns_helper_module

module AppHelper
  class TestApp
    include ActiveSupport::JSON
    include DnsHelper

    # The regex to parse the ssh output from the create app results
    SSH_OUTPUT_PATTERN = %r|ssh://([^@]+)@([^/]+)|

    # attributes to represent the general information of the application
    attr_accessor :name, :namespace, :login, :password, :type, :hostname, :repo, :file, :embed, :snapshot, :uid

    # attributes to represent the state of the rhc_create_* commands
    attr_accessor :create_domain_code, :create_app_code

    # attributes that contain statistics based on calls to connect
    attr_accessor :response_code, :response_time

    # mysql connection information
    attr_accessor :mysql_hostname, :mysql_user, :mysql_password, :mysql_database

    # Create the data structure for a test application
    def initialize(namespace, login, type, name, password="xyz123")
      @name, @namespace, @login, @type, @password = name, namespace, login, type, password
      @hostname = "#{name}-#{namespace}.#{$domain}"
      @repo = "#{$temp}/#{namespace}_#{name}_repo"
      @file = "#{$temp}/#{namespace}.json"
      @embed = []
    end

    def self.create_unique(type, name="test")
      loop do
        # Generate a random username
        chars = ("1".."9").to_a
        namespace = "ci" + Array.new(8, '').collect{chars[rand(chars.size)]}.join
        login = "cucumber-test+#{namespace}@example.com"
        app = TestApp.new(namespace, login, type, name)
        unless app.reserved?
          app.persist
          return app
        end
      end
    end

    def self.find_on_fs
      Dir.glob("#{$temp}/*.json").collect {|f| TestApp.from_file(f)}
    end

    def self.from_file(filename)
      TestApp.from_json(ActiveSupport::JSON.decode(File.open(filename, "r") {|f| f.readlines}[0]))
    end

    def self.from_json(json)
      app = TestApp.new(json['namespace'], json['login'], json['type'], json['name'])
      app.embed = json['embed']
      app.mysql_user = json['mysql_user']
      app.mysql_password = json['mysql_password']
      app.mysql_hostname = json['mysql_hostname']
      app.uid = json['uid']
      return app
    end

    def update_uid(std_output)
      match = std_output.map {|line| line.match(SSH_OUTPUT_PATTERN)}.compact[0]
      @uid = match[1]
    end

    def get_log(prefix)
      "#{$temp}/#{prefix}_#{@name}-#{@namespace}.log"
    end

    def persist
      File.open(@file, "w") {|f| f.puts self.to_json}
    end

    def reserved?
      return (!namespace_available?(@namespace) or File.exists?(@file))
    end

    def has_domain?
      return create_domain_code == 0
    end

    def get_index_file
      case @type
        when "php-5.3" then "php/index.php"
        when "ruby-1.8" then "config.ru"
        when "python-2.6" then "wsgi/application"
        when "perl-5.10" then "perl/index.pl"
        when "jbossas-7" then "src/main/webapp/index.html"
        when "nodejs-0.6" then "index.html"
      end
    end

    def get_mysql_file
      case @type
        when "php-5.3" then File.expand_path("../misc/php/db_test.php", File.expand_path(File.dirname(__FILE__)))
      end
    end

    def get_stop_string
      "stopped"
    end

    def curl(url, timeout=30)
      body = `curl --insecure -s --max-time #{timeout} #{url}`
      exit_code = $?.exitstatus

      return exit_code, body
    end

    def curl_head_success?(url, host=nil, http_code=200)
      response_code = curl_head(url, host)
      is_http = url.start_with?('http://')
      if (is_http && response_code.to_i == 301)
        url = "https://#{url[7..-1]}"
        response_code = curl_head(url, host)
      end
      return response_code.to_i == http_code 
    end
    
    def curl_head(url, host=nil)
      response_code = nil
      if host
        response_code = `curl -w %{http_code} --output /dev/null --insecure -s --head -H 'Host: #{host}' --max-time 30 #{url}`
      else
        response_code = `curl -w %{http_code} --output /dev/null --insecure -s --head --max-time 30 #{url}`
      end
      response_code 
    end

    def is_inaccessible?(max_retries=60)
      max_retries.times do |i|
        if !curl_head_success?("http://#{hostname}")
          return true
        else
          $logger.info("Connection still accessible / retry #{i} / #{hostname}")
          sleep 1
        end
      end
      return false
    end

    # Host is for the host header
    def is_accessible?(use_https=false, max_retries=120, host=nil)
      prefix = use_https ? "https://" : "http://"
      url = prefix + hostname

      max_retries.times do |i|
        if curl_head_success?(url, host)
          return true
        else
          $logger.info("Connection still inaccessible / retry #{i} / #{url}")
          sleep 1
        end
      end

      return false
    end

    def is_temporarily_unavailable?(use_https=false, host=nil)
      prefix = use_https ? "https://" : "http://"
      url = prefix + hostname

      if curl_head_success?(url, host, 503)
        return true
      else
        return false
      end
    end

    def last_access_file_present?
      File.exists? "/var/lib/stickshift/.last_access/#{uid}"
    end

    def connect(use_https=false, max_retries=30)
      prefix = use_https ? "https://" : "http://"
      url = prefix + hostname

      $logger.info("Connecting to #{url}")
      beginning_time = Time.now

      max_retries.times do |i|
        code, body = curl(url, 1)

        if code == 0
          @response_code = code.to_i
          @response_time = Time.now - beginning_time
          $logger.info("Connection result = #{code} / #{url}")
          $logger.info("Connection response time = #{@response_time} / #{url}")
          return body
        else
          $logger.info("Connection failed / retry #{i} / #{url}")
          sleep 1
        end
      end

      return nil
    end
  end
end
World(AppHelper)