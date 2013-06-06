ENV["TEST_NAME"] = "unit_application_test"
require 'test_helper'
require 'openshift-origin-controller'

#module Rails
  #def self.logger
    #l = Mocha::Mock.new("logger")
    #l.stubs(:debug)
    #l.stubs(:info)
    #l.stubs(:add)
    #l
  #end
#end

class ApplicationsTest < ActionDispatch::IntegrationTest #ActiveSupport::TestCase
  def setup
    #setup test user auth on the mongo db
    system "/usr/bin/mongo localhost/openshift_broker_dev --eval 'db.addUser(\"openshift\", \"mooo\")' 2>&1 > /dev/null"
    register_user
    @namespace = "domain" + gen_uuid[0..9]
    @user = CloudUser.new(login: $user)
    @user.save
    @domain = Domain.new(namespace: @namespace, owner: @user)
    @domain.save
    Lock.create_lock(@user)
    stubber
  end

  test "create and destroy embedded application" do
    @appname = "test"
    app = Application.create_app(@appname, [PHP_VERSION, MYSQL_VERSION], @domain, "small")
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    app.destroy_app
  end

  test "create and destroy embedded scalable application" do
    @appname = "test"
    app = Application.create_app(@appname, [PHP_VERSION, MYSQL_VERSION], @domain, "small", true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    app.destroy_app
  end

  test "scalable application events" do
    @appname = "test"
    app = Application.create_app(@appname, [PHP_VERSION, MYSQL_VERSION], @domain, "small", true)
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
    app = Application.create_app(@appname, [RUBY_VERSION, MYSQL_VERSION], @domain, "small", true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil
    app.threaddump
    app.destroy_app
  end

  test "scaling and storage events on application" do
    @appname = "test"
    app = Application.create_app(@appname, [PHP_VERSION, MYSQL_VERSION], @domain, "small", true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    @user.capabilities["max_untracked_addtl_storage_per_gear"] = 5
    @user.save
    app.reload
    component_instance = app.component_instances.find_by(cartridge_name: PHP_VERSION)
    group_instance = app.group_instances_with_scale.select{ |go| go.all_component_instances.include? component_instance }[0]
    app.update_component_limits(component_instance, nil, nil, 2)
    app.update_component_limits(component_instance, 1, 2, nil)
    app.update_component_limits(component_instance, 1, -1, nil)

    web_framework_component_instance = app.component_instances.select{ |c| CartridgeCache.find_cartridge(c.cartridge_name).categories.include?("web_framework") }.first
    app.scale_by(web_framework_component_instance.group_instance_id, 1)
    app.reload
    count = app.group_instances.map { |gi| gi.gears }.flatten.count
    assert_equal count, 3

    app.scale_by(web_framework_component_instance.group_instance_id, -1)
    resp = rest_check(:get, "", {})
    assert_equal resp.status, 200

    app.reload
    count = app.group_instances.map { |gi| gi.gears }.flatten.count
    assert_equal count, 2

    app.destroy_app
  end

  test "application events through internal rest" do
    @appname = "test"
    app = Application.create_app(@appname, [RUBY_VERSION, MYSQL_VERSION], @domain, "small", true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    resp = rest_check(:get, "", {})
    assert_equal resp.status, 200

    resp = rest_check(:put, "/cartridges/#{RUBY_VERSION}", { "scales_from" => 2, "scales_to" => 2})
    assert_equal resp.status, 200

    resp = rest_check(:put, "/cartridges/#{RUBY_VERSION}", {})
    assert_equal resp.status, 422

    resp = rest_check(:get, "/cartridges", {})
    assert_equal resp.status, 200

    resp = rest_check(:post, "/events", { "event" => "thread-dump" })
    assert_equal resp.status, 200

    resp = rest_check(:post, "/events", { "event" => "reload" })
    assert_equal resp.status, 200

    resp = rest_check(:post, "/events", { "event" => "tidy" })
    assert_equal resp.status, 200

    component_instance = app.component_instances.find_by(cartridge_name: RUBY_VERSION)
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
    request_via_redirect(:get, "/rest/user", {}, headers)
    assert_equal @response.status, 200
  end

  def rest_check(method, resource, params)
    uri = "/domains/#{@namespace}/applications/#{@appname}" + resource
    credentials = Base64.encode64("#{$user}:#{$password}")
    headers = {}
    headers["HTTP_ACCEPT"] = "application/json" 
    headers["HTTP_AUTHORIZATION"] = "Basic #{credentials}"
    request_via_redirect(method, "/rest" + uri, params, headers)
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
