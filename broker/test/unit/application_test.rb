ENV["TEST_NAME"] = "unit_application_test"
require 'test_helper'
require 'openshift-origin-controller'
require 'helpers/rest/api'

class ApplicationsTest < ActionDispatch::IntegrationTest #ActiveSupport::TestCase
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
    @appname = "test"
    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql), @domain)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil 
    
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

  test "create update and destroy scalable application" do
    @appname = "test"
    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql), @domain, nil, true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil
    
    app.config['auto_deploy'] = true
    app.config['deployment_branch'] = "stage"
    app.config['keep_deployments'] = 3
    app.config['deployment_type'] = "binary"
    app.update_configuration
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    assert app.config['auto_deploy'] == true
    puts app.config['deployment_branch']
    #assert app.config['deployment_branch'] == "stage"
    assert app.config['keep_deployments'] == 3
    assert app.config['deployment_type'] == "binary"

    app.destroy_app
  end
  
  test "app config validation" do
    @appname = "test"
    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql), @domain, nil, true)
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
    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql), @domain, nil, true)
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
    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql), @domain, nil, true)
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
    app = Application.create_app(@appname, cartridge_instances_for(:ruby, :mysql), @domain, nil, true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil
    app.threaddump
    app.destroy_app
  end

  test "scaling and storage events on application" do
    @appname = "test"

    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql), @domain, nil, true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    @user.max_untracked_additional_storage = 5
    @user.save
    app.reload
    app.owner.reload
    component_instance = app.component_instances.find_by(cartridge_name: php_version)
    group_instance = app.group_instances_with_scale.select{ |go| go.all_component_instances.include? component_instance }[0]
    app.update_component_limits(component_instance, nil, nil, 2)
    app.update_component_limits(component_instance, 1, 2, nil)
    app.update_component_limits(component_instance, 1, -1, nil)

    web_framework_component_instance = app.component_instances.select{ |c| CartridgeCache.find_cartridge(c.cartridge_name).categories.include?("web_framework") }.first
    app.scale_by(web_framework_component_instance.group_instance_id, 1)
    app.reload
    assert_equal app.gears.count, 3

    app.scale_by(web_framework_component_instance.group_instance_id, -1)
    resp = rest_check(:get, "", {})
    assert_equal resp.status, 200

    app.reload
    assert_equal app.gears.count, 2

    app.destroy_app
  end

  test "application events through internal rest" do
    @appname = "test"
    app = Application.create_app(@appname, cartridge_instances_for(:ruby, :mysql), @domain, nil, true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    resp = rest_check(:get, "", {})
    assert_equal resp.status, 200

    resp = rest_check(:put, "/cartridges/#{ruby_version}", { "scales_from" => 2, "scales_to" => 2})
    assert_equal resp.status, 200

    resp = rest_check(:put, "/cartridges/#{ruby_version}", {})
    assert_equal resp.status, 422

    resp = rest_check(:get, "/cartridges", {})
    assert_equal resp.status, 200

    resp = rest_check(:post, "/events", { "event" => "thread-dump" })
    assert_equal resp.status, 200

    resp = rest_check(:post, "/events", { "event" => "reload" })
    assert_equal resp.status, 200

    resp = rest_check(:post, "/events", { "event" => "tidy" })
    assert_equal resp.status, 200

    component_instance = app.component_instances.find_by(cartridge_name: ruby_version)
    group_instance = app.group_instances_with_scale.select{ |go| go.all_component_instances.include? component_instance }[0]
    resp = rest_check(:get, "/gear_groups/#{group_instance._id.to_s}", { })
    assert_equal resp.status, 200

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
