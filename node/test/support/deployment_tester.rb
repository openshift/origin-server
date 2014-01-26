require_relative 'functional_api'

require 'test/unit/assertions'
require 'mocha/setup'

module OpenShift
  module Runtime
  end
end

class OpenShift::Runtime::DeploymentTester
  include Test::Unit::Assertions
  include OpenShift::Runtime::NodeLogger

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
    keep_deployments = options[:keep_deployments]

    app_name = "app#{@api.random_string}"

    app_id = @api.create_application(app_name, cartridges, scaling)
    @api.add_ssh_key(app_id, app_name)

    framework = cartridges[0]

    app_container = OpenShift::Runtime::ApplicationContainer.from_uuid(app_id)

    if keep_deployments
      # keep up to #{keep} deployments
      logger.info "Setting OPENSHIFT_KEEP_DEPLOYMENTS to #{keep_deployments} for #{@namespace}"
      @api.configure_application(app_name, keep_deployments: keep_deployments)

      gear_env = OpenShift::Runtime::Utils::Environ.for_gear(app_container.container_dir)

      assert_equal keep_deployments.to_s, gear_env['OPENSHIFT_KEEP_DEPLOYMENTS'], "Keep deployments value was not actually updated"
    end

    assert_gear_deployment_consistency(@api.gears_for_app(app_name), keep_deployments)

    if scaling
      gear_registry = OpenShift::Runtime::GearRegistry.new(app_container)
      entries = gear_registry.entries
      logger.info("Gear registry contents: #{entries}")
      assert_equal 2, entries.keys.size

      web_entries = entries[:web]
      assert_equal 1, web_entries.keys.size
      assert_equal app_id, web_entries.keys[0]

      entry = web_entries[app_id]
      assert_equal app_id, entry.uuid
      assert_equal @namespace, entry.namespace

      domain = @api.cloud_domain

      assert_equal "#{app_name}-#{@namespace}.#{domain}", entry.dns
      local_hostname = `facter public_hostname`.chomp
      assert_equal local_hostname, entry.proxy_hostname

      @api.assert_http_title_for_entry entry, DEFAULT_TITLE, "Default title check for head gear failed"

      proxy_entries = entries[:proxy]
      assert_equal 1, proxy_entries.keys.size
      assert_equal app_id, proxy_entries.keys[0]
      entry = proxy_entries[app_id]
      assert_equal app_id, entry.uuid
      assert_equal @namespace, entry.namespace
      assert_equal "#{app_name}-#{@namespace}.#{domain}", entry.dns
      assert_equal local_hostname, entry.proxy_hostname
      assert_equal 0, entry.proxy_port.to_i

      # scale up to 2
      @api.assert_scales_to app_name, framework, 2

      assert_gear_deployment_consistency(@api.gears_for_app(app_name), keep_deployments)

      gear_registry.load
      entries = gear_registry.entries
      assert_equal 2, entries.keys.size
      web_entries = entries[:web]
      assert_equal 2, web_entries.keys.size

      # make sure the http content is good
      web_entries.values.each do |entry|
        logger.info("Checking title for #{entry.as_json}")
        @api.assert_http_title_for_entry entry, DEFAULT_TITLE, "Default title check for secondary gear failed"
      end
    else
      @api.assert_http_title_for_app app_name, @namespace, DEFAULT_TITLE, "Default title check failed"
    end

    deployment_metadata = app_container.deployment_metadata_for(app_container.current_deployment_datetime)
    deployment_id = deployment_metadata.id

    @api.clone_repo(app_id)
    @api.change_title(CHANGED_TITLE, app_name, app_id, framework)

    assert_gear_deployment_consistency(@api.gears_for_app(app_name), keep_deployments)

    if scaling
      web_entries.values.each { |entry| @api.assert_http_title_for_entry entry, CHANGED_TITLE, "Check for changed title before scale-up failed" }

      @api.assert_scales_to app_name, framework, 3

      assert_gear_deployment_consistency(@api.gears_for_app(app_name), keep_deployments)

      gear_registry.load
      entries = gear_registry.entries
      assert_equal 3, entries[:web].size

      entries[:web].values.each { |entry| @api.assert_http_title_for_entry entry, CHANGED_TITLE, "Check for changed title after scale-up failed" }
    else
      @api.assert_http_title_for_app app_name, @namespace, CHANGED_TITLE, "Check for changed title failed"
    end

    if add_jenkins
      @api.add_cartridge('jenkins-client-1', app_name)

      @api.change_title(JENKINS_ADD_TITLE, app_name, app_id, framework)

      assert_gear_deployment_consistency(@api.gears_for_app(app_name), keep_deployments)

      if scaling
        entries = gear_registry.entries
        entries[:web].values.each { |entry| @api.assert_http_title_for_entry entry, JENKINS_ADD_TITLE }
      else
        @api.assert_http_title_for_app app_name, @namespace, JENKINS_ADD_TITLE
      end
    end

    if !keep_deployments.nil? && keep_deployments > 1
      # rollback
      logger.info("Rolling back to #{deployment_id}")
      logger.info @api.ssh_command(app_id, "gear activate #{deployment_id} --all")

      assert_gear_deployment_consistency(@api.gears_for_app(app_name), keep_deployments)

      if scaling
        entries = gear_registry.entries
        entries[:web].values.each { |entry| @api.assert_http_title_for_entry entry, DEFAULT_TITLE, "Default title check after rollback failed" }
      else
        @api.assert_http_title_for_app app_name, @namespace, DEFAULT_TITLE, "Default title check after rollback failed"
      end
    end
  end

  def assert_gear_deployment_consistency(gears, keep_deployments)
    errors = []
    deployments_to_keep ||= 1

    gears.each do |gear|
      container = OpenShift::Runtime::ApplicationContainer.from_uuid(gear)
      logger.info "Validating deployments for #{gear}"

      all_deployments = container.all_deployments

      assert_operator all_deployments.length, :<=, keep_deployments if keep_deployments

      all_deployments.each do |deployment|
        %w(dependencies build-dependencies repo).each do |dir|
          path = File.join(deployment, dir)
          errors << "Broken or missing dir #{path}" unless File.exists?(path)
        end
      end
    end

    assert_equal 0, errors.length, "Corrupted deployment directories:\n#{errors.join("\n")}"
  end
end
