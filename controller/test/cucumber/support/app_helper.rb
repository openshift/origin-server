require 'active_support'

module AppHelper
  class TestApp
    include ActiveSupport::JSON

    # The regex to parse the ssh output from the create app results
    SSH_OUTPUT_PATTERN = %r|ssh://([^@]+)@([^/]+)|

    # Default password
    DEFPASSWD = "xyz123"

    # attributes to represent the general information of the application
    attr_accessor :name, :namespace, :login, :password, :type, :hostname, :repo, :file, :embed, :snapshot, :uid, :git_url, :owner, :scalable

    # attributes to represent the state of the rhc_create_* commands
    attr_accessor :create_domain_code, :create_app_code

    # attributes that contain statistics based on calls to connect
    attr_accessor :response_code, :response_time

    # mysql connection information
    attr_accessor :mysql_hostname, :mysql_user, :mysql_password, :mysql_database

    # jenkins connection information
    attr_accessor :jenkins_url, :jenkins_job_url, :jenkins_user, :jenkins_password, :jenkins_build

    # Create the data structure for a test application
    def initialize(namespace, login, type, name, password, owner, scalable = false)
      @name, @namespace, @login, @type, @password, @owner = name, namespace, login, type, password, owner
      @hostname = "#{name}-#{namespace}.#{$domain}"
      @repo = "#{$temp}/#{namespace}_#{name}_repo"
      @file = "#{$temp}/#{namespace}_#{name}.json"
      @embed = []
      @scalable = scalable
    end

    RANDOM_RANGE = [('a'..'z'),('A'..'Z'),("1".."9")].inject([]){|ret,v| ret |= v.to_a }
    def self.random_string(len = 8, charspace = RANDOM_RANGE)
      # Make sure this is an Array in case we pass a range
      charspace = charspace.to_a
      (0...len).map{ charspace[rand(charspace.length)] }.join
    end

    def self.create_unique(type, name=nil, scalable=false)
      chars = ("1".."9").to_a
      loop do
        # Generate a random username
        name ||= random_string(8, chars)
        namespace = "ci" + random_string(8, chars)
        login = "cucumber-test_#{namespace}@example.com"
        app = TestApp.new(namespace, login, type, name, DEFPASSWD, Process.pid, scalable)
        unless app.reserved?
          app.persist
          return app
        end
      end
    end

    def self.create_app_from_params(namespace, login, type, password, scalable=false)
      chars = ("1".."9").to_a
      # Generate a random name
      name ||= random_string(8, chars)
      app = TestApp.new(namespace, login, type, name, password, Process.pid, scalable)
      return app
    end

    def self.find_on_fs
      Dir.glob("#{$temp}/*.json").collect {|f| TestApp.from_file(f)}.select { |app| ( ( app.owner == Process.pid ) or app.owner.nil? ) }
    end

    def self.from_file(filename)
      TestApp.from_json(ActiveSupport::JSON.decode(File.open(filename, "r") {|f| f.readlines}[0]))
    end

    def self.from_json(json)
      app = TestApp.new(json['namespace'], json['login'], json['type'], json['name'], json['password'], json['owner'])
      app.embed = json['embed']
      app.mysql_user = json['mysql_user']
      app.mysql_password = json['mysql_password']
      app.mysql_hostname = json['mysql_hostname']
      app.uid = json['uid']
      return app
    end

    def update_jenkins_info
      @jenkins_user     = IO.read("/var/lib/openshift/#{@uid}/.env/JENKINS_USERNAME").chomp
      @jenkins_password = IO.read("/var/lib/openshift/#{@uid}/.env/JENKINS_PASSWORD").chomp
      @jenkins_url      = IO.read("/var/lib/openshift/#{@uid}/.env/JENKINS_URL").chomp

      @jenkins_job_url = "#{@jenkins_url}job/#{@name}-build/"
      @jenkins_build   = "curl -ksS -X GET #{@jenkins_job_url}api/json --user '#{@jenkins_user}:#{@jenkins_password}'"

      $logger.debug %Q{
jenkins_url      = #{@jenkins_url}
jenkins_user     = #{@jenkins_user}
jenkins_password = #{@jenkins_password}
jenkins_build    = #{@jenkins_build}
                    }
    end

    def update_uid(std_output)
      begin
        match = std_output.lines.map {|line| line.match(SSH_OUTPUT_PATTERN)}.compact[0]
        @uid = match[1]
      rescue => e
        $logger.error "update_uid failed: #{e.message}\n#{std_output}"
      end
    end

    def update_git_url(std_output)
      match = std_output.map {|line| line.match(%r|git url: (.*)|)}
      @git_url = match.compact.first[1] if not match.nil?
    end

    def get_log(prefix)
      "#{$temp}/#{prefix}_#{@name}-#{@namespace}.log"
    end

    def persist
      # Because the system I/O is high during testing, this doesn't always
      # succeed right away.
      success=false
      5.times do
        begin
          File.open(@file, "w") {|f| f.puts self.to_json}
          success=true
          $logger.debug("Successfully wrote file #{@file}")
          break
        rescue Errno::ENOENT
          $logger.error("Retrying file write for #{@file}")
        end
        if !success
          raise "Failed to write to #{@file}"
        end
      end
    end

    def reserved?
      #TODO Should we check for unique ns here?
      return File.exists?(@file)
    end

    def has_domain?
      return create_domain_code == 0
    end

    def get_index_file
      case @type.gsub(/-.*/,'')
        when "php"      then "index.php"
        when "ruby"     then "config.ru"
        when "python"   then "wsgi.py"
        when "perl"     then "index.pl"
        when "jbossas"  then "src/main/webapp/index.html"
        when "jbosseap" then "src/main/webapp/index.html"
        when "jbossews" then "src/main/webapp/index.html"
        when "nodejs"   then "index.html"
      end
    end

    def get_pom_file
      case @type.gsub(/-.*/,'')
        when "jbossas"  then "pom.xml"
        when "jbosseap" then "pom.xml"
        when "jbossews" then "pom.xml"
      end
    end

    def get_standalone_config
      case @type.gsub(/-.*/,'')
        when "jbossas"  then ".openshift/config/standalone.xml"
        when "jbosseap" then ".openshift/config/standalone.xml"
      end
    end

    def get_mysql_file
      if @type.start_with?("php-5")
        File.expand_path("../misc/php/db_test.php", File.expand_path(File.dirname(__FILE__)))
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
      if (is_http && (response_code.to_i == 301 || response_code.to_i == 302))
        url = "https://#{url[7..-1]}"
        response_code = curl_head(url, host)
      end
      return response_code.to_i == http_code
    end

    def curl_head(url, host=nil)
      auth = "--user #{@jenkins_user}:#{@jenkins_password}" if @jenkins_user
      host = "-H 'Host: #{host}'" if host
      `curl -w %{http_code} --output /dev/null --insecure -s --head --max-time 30 #{auth} #{host} #{url}`
    end

    def is_inaccessible?(max_retries=60, port=nil)
      max_retries.times do |i|
        url = "http://#{hostname}"
        if port
          url = "http://#{hostname}:#{port}"
        end
        if !curl_head_success?(url)
          return true
        else
          $logger.info("Connection still accessible / retry #{i} of #{max_retries} / #{hostname}")
          sleep 1
        end
      end
      return false
    end

    # Host is for the host header
    def is_accessible?(use_https=false, max_retries=120, host=nil, port=nil)
      return is_path_accessible?(use_https, max_retries, nil, host, port)
    end

    def is_path_accessible?(use_https=false, max_retries=120, path=nil, host=nil, port=nil)
      prefix = use_https ? "https://" : "http://"
      url = prefix + hostname

      if port
         url = url + ":" + port.to_s
      end

      if path
        url = url + path
      end

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
      File.exists? "/var/lib/openshift/.last_access/#{uid}"
    end

    def connect(use_https=false, max_retries=30, timeout=1, path="")
      prefix = use_https ? "https://" : "http://"
      url = prefix + hostname + path

      $logger.info("Connecting to #{url}")
      beginning_time = Time.now

      max_retries.times do |i|
        code, body = curl(url, timeout)

        if code == 0
          @response_code = code.to_i
          @response_time = Time.now - beginning_time
          $logger.info("Connection result = #{code} / #{url}")
          $logger.info("Connection response time = #{@response_time} / #{url}")
          return body
        else
          $logger.info("Connection failed / retry #{i} of #{max_retries} / #{url}")
          sleep 1
        end
      end

      return nil
    end

    def ssh_command(command)
      cmd = "ssh 2>/dev/null -o BatchMode=yes -o StrictHostKeyChecking=no -tt #{uid}@#{name}-#{namespace}.#{$domain} " + command

      $logger.debug "Running #{cmd}"

      output = `#{cmd}`
      $logger.debug "Output: #{output}"

      output.strip
    end

    def scp_file(src, dest='/tmp/')
      if dest.end_with?("/")
        dest = File.join(dest,File.basename(src))
      end
      cmd = "scp 2>/dev/null -o StrictHostKeyChecking=no #{src} #{uid}@#{name}-#{namespace}.#{$domain}:#{dest}"

      $logger.debug "Running #{cmd}"

      output = `#{cmd}`
      $logger.debug "Output: #{output}"

      dest
    end

    def scp_content(content, dest = "/tmp/")
      tmpfile = Tempfile.new('')
      File.open(tmpfile,'w') do |f|
        f.write(content)
      end
      tmpfile.close
      scp_file(tmpfile.path, dest)
    ensure
      tmpfile.unlink
    end
  end
end
World(AppHelper)
