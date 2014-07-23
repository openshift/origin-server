# A small support API for runtime-centric test cases. It provides
# abstractions for an Account, Application, Gear, and Cartridge.
# The gear implementation is backed by ApplicationContainer from
# the openshift-origin-node package.
#
# Parts of this might be flimsy and not quite aligned with certain
# realities (especially with regards to scaling), but it should
# provide a decent starting point for the runtime tests and give
# us a single place to refactor.

require 'openshift-origin-node'
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/model/ident'
require 'etc'
require 'timeout'
require 'json'

# Some constants which might be misplaced here. Perhaps they should
# go in 00_setup_helper.rb?
$home_root ||= "/var/lib/openshift"
$cartridge_root ||= "/usr/libexec/openshift/cartridges"
$embedded_cartridge_root ||= "/usr/libexec/openshift/cartridges/embedded"

$app_registry = {}

# Utilities to facilitate code sharing between runtime_support
# and app_helper based tests.
def current_test_app_uuid
  if defined?(@gear)
    @gear.uuid
  elsif defined?(@app) && @app.respond_to?(:uid)
    @app.uid
  else
    raise "Neither @app nor @gear is defined"
  end
end

def current_app_namespace
  if defined?(@account)
    @account.domain
  elsif defined?(@app) && @app.respond_to?(:namespace)
    @app.namespace
  else
    raise "Neither @acount nor @app is defined"
  end
end

module OpenShift
  TIMEOUT = 120

  # Represents a user account. A name and domain will be automatically
  # generated upon init,
  class TestAccount
    attr_reader :name, :domain, :apps

    def initialize(domain=nil)
      @name, @domain = gen_unique_login_and_domain(domain)
      @apps = Array.new

      # shouldn't do stuff in the constructor, but we'll live
      $logger.info("Created new account #{@name} with domain #{@domain}")
    end

    # Lifted from another test script.
    def gen_unique_login_and_domain(domain=nil)
      if !domain
        chars = ("1".."9").to_a
        domain = "ci" + Array.new(8, '').collect{chars[rand(chars.size)]}.join
      end
      login = "cucumber-test_#{domain}@example.com"
      [ login, domain ]
    end

    # Creates a new TestApplication instance associated with this account.
    def create_app()
      app = OpenShift::TestApplication.new(self)

      $logger.info("Created new application #{app.name} for account #{@name}")

      @apps << app
      app
    end

    # Convenience function to get the first application for this account.
    def default_app()
      @apps[0]
    end
  end

  # Represents an application associated with an account. The name and
  # UUID for the application is automatically generated upon init.
  class TestApplication
    attr_reader :name, :uuid, :account, :gears
    attr_accessor :hot_deploy_enabled, :git_repo

    def initialize(account)
      @name = gen_unique_app_name
      @uuid = gen_small_uuid
      @account = account
      @gears = Array.new

      # abstracts the hot_deploy marker file as a first class
      # property of the application
      @hot_deploy_enabled = false
    end

    # Lifted from another script.
    def gen_unique_app_name
      chars = ("1".."9").to_a
      "app" + Array.new(4, '').collect{chars[rand(chars.size)]}.join
    end

    # Lifted from another script.
    def gen_small_uuid
      %x[/usr/bin/uuidgen].gsub('-', '').strip
    end

    # Creates a new empty gear associated with this application.
    def create_gear(cli = false)
      gear = OpenShift::TestGear.new(self)
      gear.create(cli)
      @gears << gear
      gear
    end

    # Convenience function to get the first gear associated with
    # this application.
    def default_gear
      @gears[0]
    end

    # Tears down the application by calling destroy for each gear.
    def destroy
      $logger.info("Destroying application #{@name}")
      @gears.each do |gear|
        gear.destroy
      end
    end

    def start
      default_gear.container.start_gear
    end

    def stop
      default_gear.container.stop_gear
    end

    def tidy
      default_gear.container.tidy
    end

    def restart
      default_gear.container.restart(default_gear.default_cart.name)
    end

    def status
      default_gear.container.status(default_gear.default_cart.name)
    end

    def reload
      default_gear.container.reload(default_gear.default_cart.name)
    end

    # Collects and returns the PIDs for every cartridge associated
    # with this application as determined by the PID file in the
    # cartridge instance run directory. The result is a Hash:
    #
    #   PID file basename => PID
    #
    # NOTE: This doesn't currently take into account the possibility
    # of duplicate PID filenames across gears (in a scaled instance).
    def current_cart_pids
      pids = {}

      @gears.each do |gear|
        gear.carts.values.each do |cart|
          Dir.glob("#{$home_root}/#{gear.uuid}/#{cart.directory}/{run,pid}/*.pid") do |pid_file|
            $logger.info("Reading pid file #{pid_file} for cart #{cart.name}")
            pid = IO.read(pid_file).chomp
            proc_name = File.basename(pid_file, ".pid")

            pids[proc_name] = pid
          end
        end
      end

      pids
    end
  end

  # Represents a gear associated with an application. The UUID for the gear
  # is automatically generated on init.
  #
  # NOTE: Instantiating the TestGear is not enough for it to be used; make
  # sure to call TestGear.create before performing cartridge operations.
  class TestGear
    include CommandHelper

    attr_reader :uuid, :carts, :app, :container

    def initialize(app)
      @uuid = gen_small_uuid
      @carts = Hash.new # cart name => cart
      @app = app
    end

    # Lifted from another script.
    def gen_small_uuid()
      %x[/usr/bin/uuidgen].gsub('-', '').strip
    end

    # Creates the physical gear on a node by delegating work to the
    # ApplicationContainer class. Be sure to call this before attempting
    # cartridge operations.
    def create(cli = false)
      $logger.info("Creating new gear #{@uuid} for application #{@app.name}")

      if cli
        command = %Q(oo-devel-node app-create -c #{uuid} -a #{@app.uuid} --with-namespace #{@app.account.domain} --with-app-name #{@app.name} --with-secret-token=DEADBEEFDEADBEEFDEADBEEFDEADBEEF)
        $logger.info(%Q(Running #{command}))
        results = %x[#{command}]
        assert_equal(0, $?.exitstatus, %Q(#{command}\n #{results}))
      end

      # Create the container object for use in the event listener later
      begin
        @container = OpenShift::Runtime::ApplicationContainer.new(@app.uuid, @uuid, nil, @app.name, @app.name, @app.account.domain, nil, nil)
      rescue Exception => e
        $logger.error("#{e.message}\n#{e.backtrace}")
        raise
      end

      unless cli
        @container.create('DEADBEEFDEADBEEFDEADBEEFDEADBEEF')
      end
    end

    # Destroys the gear via ApplicationContainer
    def destroy()
      $logger.info("Destroying gear #{@uuid} of application #{@app.name}")

      @container.destroy(true)
    end

    # Adds an alias to the gear
    def add_alias(alias_name)
      $logger.info("Adding alias #{alias_name} to gear #{@uuid} of application #{@app.name}")

      frontend = OpenShift::Runtime::FrontendHttpServer.new(OpenShift::Runtime::ApplicationContainer.from_uuid(@uuid))
      frontend.add_alias(alias_name)
    end

    # Removes an alias from the gear
    # Adds an alias to the gear
    def remove_alias(alias_name)
      $logger.info("Adding alias #{alias_name} to gear #{@uuid} of application #{@app.name}")

      frontend = OpenShift::Runtime::FrontendHttpServer.new(OpenShift::Runtime::ApplicationContainer.from_uuid(@uuid))
      frontend.remove_alias(alias_name)
    end

    # List FrontendHttpServer proxy for the gear
    def list_http_proxy_paths
      $logger.info("Checking routes for gear #{@uuid} of application #{@app.name}")
      frontend = OpenShift::Runtime::FrontendHttpServer.new(OpenShift::Runtime::ApplicationContainer.from_uuid(@uuid))
      Hash[*frontend.connections.map { |path, uri, opts| [path, [uri, opts ] ] }.flatten(1)]
    end

    # Creates a new TestCartridge and associates it with this gear.
    #
    # NOTE: The cartridge is instantiated, but no hooks (such as
    # configure) are executed.
    def add_cartridge(cart_name)
      cart = OpenShift::TestCartridge.new(cart_name, self)
      @carts[cart.name] = cart
      cart
    end

    # Convenience function to retrieve the first cartridge for the gear.
    def default_cart()
      @carts.values[0]
    end
  end

  # Represents a cartridge associated with a gear. Supports firing events
  # and listener registration for cartridge-specific concerns.
  class TestCartridge
    include CommandHelper

    attr_reader :name, :gear, :path, :metadata

    def initialize(name, gear)
      unless name.match('-')
        cart_list = JSON.parse(`oo-devel-node cartridge-list --porcelain`[15..-1])
        cart_list.delete_if{ |c| not c.start_with? name }
        name = cart_list.first
      end

      @name = name
      @gear = gear

      @metadata = {} # a place for cart specific helpers to put stuff

      # Add new listener classes here for now
      @listeners = [ OpenShift::TestCartridgeListeners::ConfigureCartListener.new,
                     OpenShift::TestCartridgeListeners::DatabaseCartListener.new
                   ]
    end

    def configure(cli = false)
      output = ""

      if cli
        output = `oo-cartridge -a add -c #{@gear.uuid} -n #{@name} -v`
      else
        with_container do |container|
          tokens =  @name.split(/\-([0-9\.]+)$/)
          ident = OpenShift::Runtime::Ident.new('redhat', tokens[0], tokens[1])
          output = container.configure(ident)
          output << container.post_configure(ident.to_name)
        end
      end

      # Sanitize the command output. For now, the only major problem we're aware
      # of is colorized output containing escape characters. The sanitization should
      # really be taken care of in downstream formatters, but we have no control over
      # those at present.
      output = output.gsub(/\e\[(\d+)m/, '')

      notify_listeners "configure_hook_completed", { :cart => self, :output => output}
    end

    def deconfigure
      with_container do |container|
          tokens =  @name.split(/\-([0-9\.]+)$/)
          ident = OpenShift::Runtime::Ident.new('redhat', tokens[0], tokens[1])
          container.deconfigure(ident)
      end
    end

    def start
      with_container do |container|
        container.start(@name)
      end
    end

    def stop
      with_container do |container|
        container.stop(@name)
      end
    end

    def status()
      with_container do |container|
        container.status(@name)
      end
    end

    def restart()
      with_container do |container|
        container.restart(@name)
      end
    end

    def tidy()
      with_container do |container|
        container.tidy
      end
    end

    def directory
      inst = @gear.container.cartridge_model.get_cartridge(@name)
      inst.directory || inst.name
    end

    def with_container
      begin
        yield @gear.container
      rescue OpenShift::Runtime::Utils::ShellExecutionException => e
        $logger.error "Caught ShellExecutionException (#{e.rc}): #{e.message}; output: #{e.stdout} #{e.stderr}"
        $logger.error e.backtrace.join("\n")
        raise
      rescue => e
        $logger.error "Caught an Exception, #{e.message}"
        $logger.error e.backtrace.join("\n")
        raise
      end
    end

    # Notify cart listeners of an event
    def notify_listeners(event, args={})
      @listeners.each do |listener|
        if listener.respond_to?(event) && listener.supports?(@name)
          $logger.info("Notifying #{listener.class.name} of #{event} event")
          listener.send(event, args)
        end
      end
    end
  end

  # Cartridge listeners are intended to be invoked by TestCartridge instances
  # at various points in their lifecycle, such as post-hook. The listeners
  # are given an opportunity to respond to the results of cartridge actions
  # and attach supplementary information to the cartridge instance which
  # can be used to provide steps with cartridge specific context.
  #
  # Currently supported event patterns a listener may receive:
  #
  #   {hook_name}_hook_completed(cart, exitcode, output)
  #     - invoked after a successful hook execution in the cartridge
  module TestCartridgeListeners

    # Pretend we're the broker's application model
    class ConfigureCartListener
      # We need to process all configure output for all cartridges
      def supports?(cart_name)
        true
      end

      def configure_hook_completed(args)
        if args.key?(:output) && ! args[:output].empty?
          homedir = args[:cart].gear.container.container_dir

          args[:output].split(/\n/).each { |line|
            case line
              when /^ENV_VAR_ADD: .*/
                key, value = line['ENV_VAR_ADD: '.length..-1].chomp.split('=')
                File.open(File.join(homedir, '.env', key),
                    File::WRONLY|File::TRUNC|File::CREAT) do |file|
                      file.write "export #{key}='#{value}'"
                end
              when /^ENV_VAR_REMOVE: .*/
                key = line['ENV_VAR_REMOVE: '.length..-1].chomp
                FileUtils.rm_f File.join(homedir, '.env', key)
            end
          }
        end
      end
    end

    class DatabaseCartListener
      def supports?(cart_name)
        cart_name =~ /^(mysql|mongodb|postgresql)-[0-9\.]+/
      end

      class DbConnection
        attr_accessor :username, :password, :ip, :port
      end

      # Processes the output of the cartridge configure script and scrapes
      # it for connectivity details (such as IP and credentials).
      #
      # Adds a new attribute 'db' of type DbConnection to the cart with the
      # scraped details.
      def configure_hook_completed(args)
        $logger.info("DatabaseCartListener is processing configure hook results")

        cart = args[:cart]
        output = args[:output]

        my_username_pattern = /Root User: (\S+)/
        my_password_pattern = /Root Password: (\S+)/

        # make this smarter if there are more use cases
        ip_pattern_prefix = cart.name[/[^-]*/]
        my_ip_pattern = /#{ip_pattern_prefix}:\/\/(\d+\.\d+\.\d+\.\d+):(\d+)/

        db = DbConnection.new

        output.split(/\n/).each do |line|
          if line.match(my_username_pattern)
            db.username = $1
          end
          if line.match(my_password_pattern)
            db.password = $1
          end
          if line.match(my_ip_pattern)
            db.ip = $1
            db.port = $2
          end
        end

        $logger.info("DatabaseCartListener is adding a DbConnection to cartridge #{cart.name}: "\
                     "db.username=#{db.username}, db.password=#{db.password}, db.ip=#{db.port}, db.port=#{db.port}")
        cart.instance_variable_set(:@db, db)
        cart.instance_eval('def db; @db; end')
      end
    end
  end

  #
  # Only raise timeout exceptions...
  def self.timeout(seconds, dflt = nil)
    begin
      Timeout::timeout(seconds) do
        yield
      end
    rescue Timeout::Error
      raise if dflt.instance_of? Timeout::Error
      dflt
    end
  end
end

