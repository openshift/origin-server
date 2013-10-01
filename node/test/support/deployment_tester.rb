require_relative 'functional_api'

require 'test/unit/assertions'
require 'mocha/setup'

module OpenShift
  module Runtime
  end
end

class OpenShift::Runtime::DeploymentTester
  include Test::Unit::Assertions

  DEFAULT_TITLE     = "Welcome to OpenShift"
  CHANGED_TITLE     = "Test1"
  JENKINS_ADD_TITLE = "JenkinsClient"

  def setup
    @api = FunctionalApi.new
    @namespace = @api.create_domain
  end

  def teardown
    unless ENV['PRESERVE']
      @api.delete_domain unless @api.nil?
    end
  end

  def up_gears
    @api.up_gears
  end

  def create_jenkins
    app_name = "jenkins#{@api.random_string}"
    @api.create_application(app_name, %w(jenkins-1), false)
  end

  def basic_build_test(cartridges, options = {})
    scaling          = !!options[:scaling]
    add_jenkins      = !!options[:add_jenkins]
    keep_deployments = !!options[:keep_deployments]

    app_name = "app#{@api.random_string}"

    app_id = @api.create_application(app_name, cartridges, scaling)
    @api.add_ssh_key(app_id, app_name)

    framework = cartridges[0]

    if keep_deployments
      keep = options[:keep_deployments]
      # keep up to 3 deployments
      `oo-admin-ctl-domain -l #{@login} -n #{@namespace} -c env_add -e OPENSHIFT_KEEP_DEPLOYMENTS -v #{keep}`
    end

    app_container = OpenShift::Runtime::ApplicationContainer.from_uuid(app_id)

    if scaling
      gear_registry = OpenShift::Runtime::GearRegistry.new(app_container)
      entries = gear_registry.entries
      OpenShift::Runtime::NodeLogger.logger.info("Gear registry contents: #{entries}")
      assert_equal 2, entries.keys.size

      web_entries = entries[:web]
      assert_equal 1, web_entries.keys.size
      assert_equal app_id, web_entries.keys[0]

      entry = web_entries[app_id]
      assert_equal app_id, entry.uuid
      assert_equal @namespace, entry.namespace
      assert_equal "#{app_name}-#{@namespace}.dev.rhcloud.com", entry.dns
      local_hostname = `facter public_hostname`.chomp
      assert_equal local_hostname, entry.proxy_hostname
      assert_equal IO.read(File.join(app_container.container_dir, '.env', 'OPENSHIFT_LOAD_BALANCER_PORT')).chomp, entry.proxy_port

      assert_http_title_for_entry entry, DEFAULT_TITLE

      proxy_entries = entries[:proxy]
      assert_equal 1, proxy_entries.keys.size
      assert_equal app_id, proxy_entries.keys[0]
      entry = proxy_entries[app_id]
      assert_equal app_id, entry.uuid
      assert_equal @namespace, entry.namespace
      assert_equal "#{app_name}-#{@namespace}.dev.rhcloud.com", entry.dns
      assert_equal local_hostname, entry.proxy_hostname
      assert_equal 0, entry.proxy_port.to_i

      # scale up to 2
      @api.assert_scales_to app_name, framework, 2

      gear_registry.load
      entries = gear_registry.entries
      assert_equal 2, entries.keys.size
      web_entries = entries[:web]
      assert_equal 2, web_entries.keys.size

      # make sure the http content is good
      web_entries.values.each do |entry|
        OpenShift::Runtime::NodeLogger.logger.info("Checking title for #{entry.as_json}")
        assert_http_title_for_entry entry, DEFAULT_TITLE
      end
    else
      assert_http_title_for_app app_name, @namespace, DEFAULT_TITLE
    end

    deployment_metadata = app_container.deployment_metadata_for(app_container.current_deployment_datetime)
    deployment_id = deployment_metadata.id

    @api.clone_repo(app_id)
    @api.change_title(CHANGED_TITLE, app_name, app_id, framework)

    if scaling
      web_entries.values.each { |entry| assert_http_title_for_entry entry, CHANGED_TITLE }

      @api.assert_scales_to app_name, framework, 3
      gear_registry.load
      entries = gear_registry.entries
      assert_equal 3, entries[:web].size

      entries[:web].values.each { |entry| assert_http_title_for_entry entry, CHANGED_TITLE }
    else
      assert_http_title_for_app app_name, @namespace, CHANGED_TITLE
    end

    if add_jenkins
      @api.add_cartridge('jenkins-client-1', app_name)

      @api.change_title(JENKINS_ADD_TITLE, app_name, app_id, framework)

      if scaling
        entries = gear_registry.entries
        entries[:web].values.each { |entry| assert_http_title_for_entry entry, JENKINS_ADD_TITLE }
      else
        assert_http_title_for_app app_name, @namespace, JENKINS_ADD_TITLE
      end
    end

    # rollback
    OpenShift::Runtime::NodeLogger.logger.info("Rolling back to #{deployment_id}")
    OpenShift::Runtime::NodeLogger.logger.info `ssh -o 'StrictHostKeyChecking=no' #{app_id}@localhost gear activate #{deployment_id} --all`

    if scaling
      entries = gear_registry.entries
      entries[:web].values.each { |entry| assert_http_title_for_entry entry, DEFAULT_TITLE }
    else
      assert_http_title_for_app app_name, @namespace, DEFAULT_TITLE      
    end
  end

  def assert_http_title_for_entry(entry, expected)
    url = "http://#{entry.dns}:#{entry.proxy_port}/"
    @api.assert_http_title(url, expected)
  end

  def assert_http_title_for_app(app_name, namespace, expected)
    url = "http://#{app_name}-#{@namespace}.dev.rhcloud.com"
    @api.assert_http_title(url, expected)
  end
end
