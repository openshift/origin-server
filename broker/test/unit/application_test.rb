ENV["TEST_NAME"] = "unit_application_test"
require 'test_helper'
require 'openshift-origin-controller'
require 'helpers/rest/api'

class ApplicationsTest < ActionDispatch::IntegrationTest
  def setup
    register_user
    @namespace = "domain" + gen_uuid[0..9]
    @user = CloudUser.new(login: $user)
    @user.max_gears = 10
    @user.save!
    @domain = Domain.new(namespace: @namespace, owner: @user)
    @domain.save!
    Lock.create_lock(@user)
    stubber
  end

  def teardown
    @user.force_delete rescue nil
  end

  test "create update and destroy application" do
    Gear.any_instance.expects(:publish_routing_info).never
    Gear.any_instance.expects(:unpublish_routing_info).never
    @appname = "test"
    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql), @domain)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil
    assert_equal 1, app.group_instances.length
    assert_equal 1, app.gears.length

    app.config['auto_deploy'] = true
    app.config['deployment_branch'] = "stage"
    app.config['keep_deployments'] = 3
    app.config['deployment_type'] = "binary"
    app.update_configuration
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    assert app.config['auto_deploy'] == true
    assert app.config['deployment_branch'] == "stage"
    assert app.config['keep_deployments'] == 3
    assert app.config['deployment_type'] == "binary"

    app.destroy_app
  end

  test "initial app save failure should clean up gears" do
    e = RuntimeError.new("Failure")
    Application.any_instance.expects(:save!).raises(e)
    assert_difference "@user.consumed_gears", 0 do
      assert_difference "Application.all.count", 0 do
        assert_raises(RuntimeError){ Application.create_app("test", cartridge_instances_for(:php), @domain) }
      end
    end
  end

  test "pending operations reflected in cartridges queue" do
    app = Application.new
    assert e = app.cartridges
    assert EnumeratorArray === e
    assert_equal [], e.to_a
    assert_not_same e, app.cartridges

    app.pending_op_groups << AddFeaturesOpGroup.new(features: [php_version, mysql_version])
    assert_equal [], app.cartridges.to_a
    assert_equal [php_version, mysql_version], app.cartridges(true).to_a.map(&:name)

    app.pending_op_groups << RemoveFeaturesOpGroup.new(features: [mysql_version])
    assert_equal [], app.cartridges.to_a
    assert_equal [php_version], app.cartridges(true).to_a.map(&:name)

    @appname = "test"
    Application.any_instance.expects(:save!)
    Application.any_instance.expects(:run_jobs)
    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql), @domain)
    assert !app.persisted?

    assert_equal [php_version, mysql_version], app.cartridges.to_a.map(&:name)
    # FIXME: should remove carts that are identical except for their ID, and prefer pending carts to
    # non pending carts
    assert_equal [php_version, mysql_version, php_version, mysql_version], app.cartridges(true).to_a.map(&:name)
  end

  test "create update and destroy scalable application" do
    @appname = "test"
    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql), @domain, :scalable => true, :initial_git_url => "https://a:b@github.com/foobar/test.git")
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    assert_equal "https://github.com/foobar/test.git", app.init_git_url
    app.config['auto_deploy'] = true
    app.config['deployment_branch'] = "stage"
    app.config['keep_deployments'] = 3
    app.config['deployment_type'] = "binary"
    app.update_configuration
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    assert app.config['auto_deploy'] == true
    assert app.config['keep_deployments'] == 3
    assert app.config['deployment_type'] == "binary"

    app.destroy_app
  end

  test "create test and destroy available application" do
    @appname = "test"
    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql), @domain, :available => true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    assert app.scalable
    assert app.ha
    assert_equal 3, app.gears.count

    app.destroy_app
  end

  test "make an application highly available" do
    @appname = "test"
    app = Application.create_app(@appname, cartridge_instances_for(:php), @domain, :scalable => true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    assert app.scalable
    assert !app.ha
    assert_equal 1, app.gears.count

    app.make_ha
    app.reload
    assert app.ha
    assert_equal 2, app.gears.count
    assert app.gears.all?{ |g| g.sparse_carts.length == 1 }
    assert_equal [app.component_instances.detect{ |i| i.cartridge.is_web_proxy? }._id], app.gears.map(&:sparse_carts).flatten.uniq

    app.destroy_app
  end

  test "app config validation" do
    @appname = "test"
    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql), @domain, :scalable => true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil
    
    app.config = nil
    assert app.invalid?, "config validation failed"
    
    app.config = {'auto_deploy' => nil, 'deployment_branch' => nil, 'keep_deployments' => nil, 'deployment_type' => nil}
    assert app.invalid?, "config validation failed"
    assert_equal app.errors.messages[:config].length, 4, "Wrong number of error messages" 
    
    #reset config and try individual fields
    app.config = {'auto_deploy' => true, 'deployment_branch' => 'master', 'keep_deployments' => 1, 'deployment_type' => 'git'}
    assert app.valid?, "config validation failed where it should have succeeded"
    
    app.config['auto_deploy'] = 'blah'
    assert app.invalid?, "auto_deploy validation failed"
    assert_equal app.errors.messages[:config].length, 1, "Wrong number of error messages" 
    
    app.config['deployment_branch'] = "0" * 999
    assert app.invalid?, "deployment_branch validation failed"
    assert_equal app.errors.messages[:config].length, 2, "Wrong number of error messages"
    
    app.config['keep_deployments'] = -1
    assert app.invalid?, "keep_deployments validation failed"
    assert_equal app.errors.messages[:config].length, 3, "Wrong number of error messages"
    
    app.config['deployment_type'] = "blah"
    assert app.invalid?, "deployment_type validation failed"
    assert_equal app.errors.messages[:config].length, 4, "Wrong number of error messages"
    
    #check validation on update_config
    assert_raise(OpenShift::UserException){app.update_configuration}
    
    
  end

  test "app metadata validation" do
    @appname = "test"
    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql), @domain, :scalable => true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    [nil, {}, {'bar' => 1}, {'bar' => '1'}, {'bar' => []}, {'bar' => ['1']}, {'bar' => [1]}].each do |value|
      app.meta = value
      assert app.valid?, "Value #{value.inspect} should be allowed"
    end

    app.meta = {:bar => 1}
    assert app.invalid?, "meta validation failed"
    assert_equal ['Key bar is not a string'], app.errors.messages[:meta]

    app.meta = {'bar' => :baz}
    assert app.invalid?, "meta validation failed"
    assert_equal ['Value for \'bar\' must be a string, number, or list of strings and numbers'], app.errors.messages[:meta]

    app.meta = {'bar' => [:baz]}
    assert app.invalid?, "meta validation failed"
    assert_equal ['The array of values provided for \'bar\' must be strings or numbers'], app.errors.messages[:meta]

    app.meta = {'bar' => ['baz'*5000]}
    assert app.invalid?, "meta validation failed"
    assert_equal ['Application metadata may not be larger than 10KB - currently 14KB'], app.errors.messages[:meta]
  end

  test "scalable application events" do
    @appname = "test"
    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql), @domain, :scalable => true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil
    app.restart
    app.stop
    app.start
    app.tidy
    assert_raise(OpenShift::UserException){app.threaddump}

    as = "as.#{gen_uuid[0..9]}"
    app.add_alias(as)
    app.remove_alias(as)

    app.destroy_app
  end

  test "threaddump application events" do
    @appname = "test"
    app = Application.create_app(@appname, cartridge_instances_for(:ruby, :mysql), @domain, :scalable => true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil
    app.threaddump
    app.destroy_app
  end

  test "scaling and storage events on application" do
    @appname = "test"

    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql), @domain, :scalable => true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil
    assert_equal 2, app.gears.length
    assert_equal [], app.group_overrides

    _, updated = app.elaborate(app.cartridges, [])
    changes, moves = app.compute_diffs(app.group_instance_overrides, updated)
    assert changes.all?{ |c| c.added.empty? && c.removed.empty? && c.gear_change == 0 && c.additional_filesystem_change == 0 }, changes.inspect
    assert moves.empty?, moves.inspect

    @user.max_untracked_additional_storage = 5
    @user.save
    app.reload
    app.owner.reload

    component_instance = app.component_instances.find_by(cartridge_name: php_version)
    specs = component_instance.group_instance.all_component_instances.map(&:to_component_spec)

    app.update_component_limits(component_instance, 2, 2, nil)
    assert_equal 3, (app = Application.find(app._id)).gears.length
    assert_equal [GroupOverride.new(specs, 2, 2)], app.group_overrides

    app.update_component_limits(component_instance, nil, nil, 2)
    assert_equal 3, (app = Application.find(app._id)).gears.length
    assert_equal [GroupOverride.new(specs, nil, nil, nil, 2)], app.group_overrides

    app.update_component_limits(component_instance, 1, 2, nil)
    assert_equal 3, (app = Application.find(app._id)).gears.length
    assert_equal [GroupOverride.new(specs, nil, 2)], app.group_overrides

    app.update_component_limits(component_instance, 1, -1, nil)
    assert_equal 3, (app = Application.find(app._id)).gears.length
    assert_equal [], app.group_overrides

    web_instance = app.web_component_instance
    app.scale_by(web_instance.group_instance_id, 1)
    app.reload
    assert_equal 4, app.gears.count

    app.scale_by(web_instance.group_instance_id, -1)
    resp = rest_check(:get, "", {})
    assert_equal resp.status, 200

    app.reload
    assert_equal 3, app.gears.count

    app.destroy_app
  end

  test "application events through internal rest" do
    @appname = "test"
    app = Application.create_app(@appname, cartridge_instances_for(:ruby, :mysql), @domain, :scalable => true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    resp = rest_check(:get, "", {})
    assert_equal resp.status, 200

    resp = rest_check(:put, "/cartridges/#{ruby_version}", { "scales_from" => 2, "scales_to" => 2})
    assert_equal 200, resp.status

    resp = rest_check(:put, "/cartridges/#{ruby_version}", {})
    assert_equal 422, resp.status

    resp = rest_check(:get, "/cartridges", {})
    assert_equal 200, resp.status

    resp = rest_check(:post, "/events", { "event" => "thread-dump" })
    assert_equal 200, resp.status

    resp = rest_check(:post, "/events", { "event" => "reload" })
    assert_equal 200, resp.status

    resp = rest_check(:post, "/events", { "event" => "tidy" })
    assert_equal 200, resp.status

    component_instance = app.component_instances.find_by(cartridge_name: ruby_version)
    assert group_instance = app.group_instances.detect{ |i| i.all_component_instances.include? component_instance }
    resp = rest_check(:get, "/gear_groups/#{group_instance._id.to_s}", { })
    assert_equal resp.status, 200

    app.destroy_app
  end

  test "application elaborate does not change overrides" do
    @appname = "test"
    app = Application.create_app(@appname, cartridge_instances_for(:ruby), @domain, :scalable => true)
    assert app.group_overrides.empty?

    overrides = [
      GroupOverride.new([app.component_instances.detect{ |i| i.is_web_framework? }]),
      GroupOverride.new([app.component_instances.detect{ |i| i.is_web_proxy? }]),
      GroupOverride.new(nil),
      GroupOverride.new([nil]),
      GroupOverride.new([ComponentSpec.new("test", "other")]),
    ]

    _, groups = app.elaborate(app.cartridges, overrides)
    assert_equal 1, groups.length
    assert groups[0].implicit?

    app.reload

    overrides = [
      GroupOverride.new([app.component_instances.detect{ |i| i.is_web_framework? }]),
      GroupOverride.new([app.component_instances.detect{ |i| i.is_web_proxy? }]),
      GroupOverride.new(nil),
      GroupOverride.new([nil]),
      GroupOverride.new([ComponentSpec.new("test", "other")]),
    ]
    app.group_overrides.concat(overrides)
    ops, added, removed = app.update_requirements(app.cartridges, overrides)
    assert_equal 0, added
    assert_equal 0, removed
    assert ops.empty?
    assert ops.none?{ |t| SetGroupOverridesOp === t }

    app.reload

    app.destroy_app
  end

  test "user info through internal rest" do
    credentials = Base64.encode64("#{$user}:#{$password}")
    headers = {}
    headers["HTTP_ACCEPT"] = "application/json"
    headers["HTTP_AUTHORIZATION"] = "Basic #{credentials}"
    headers["REMOTE_USER"] = $user
    request_via_redirect(:get, "/broker/rest/user", {}, headers)
    assert_equal @response.status, 200
  end

  def rest_check(method, resource, params)
    uri = "/domains/#{@namespace}/applications/#{@appname}" + resource
    credentials = Base64.encode64("#{$user}:#{$password}")
    headers = {}
    headers["HTTP_ACCEPT"] = "application/json"
    headers["HTTP_AUTHORIZATION"] = "Basic #{credentials}"
    headers["REMOTE_USER"] = $user
    request_via_redirect(method, "/broker/rest" + uri, params, headers)
    @response
  end

  def teardown
    @domain.reload
    @domain.applications.each do |app|
      app.delete
    end
    @domain.reload.delete
    @user.reload.delete
    Mocha::Mockery.instance.stubba.unstub_all
  end
end
