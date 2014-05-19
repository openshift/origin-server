ENV["TEST_NAME"] = "functional_gear_groups_controller_test"
require 'test_helper'
require 'openshift-origin-controller'
require 'mocha/setup'

class GearGroupsControllerTest < ActionController::TestCase

  def setup
    @controller = GearGroupsController.new

    @random = rand(1000000000)
    @login = "user#{@random}"
    @password = "password"
    @user = CloudUser.new(login: @login)
    @user.private_ssl_certificates = true
    @user.save
    Lock.create_lock(@user.id)
    register_user(@login, @password)

    @request.env['HTTP_AUTHORIZATION'] = "Basic " + Base64.encode64("#{@login}:#{@password}")
    @request.env['REMOTE_USER'] = @login
    @request.env['HTTP_ACCEPT'] = "application/json"
    stubber
    @namespace = "ns#{@random}"
    @domain = Domain.new(namespace: @namespace, owner:@user)
    @domain.save
    @app_name = "app#{@random}"
    @app = Application.create_app(@app_name, cartridge_instances_for(:php), @domain)
    @app.save
  end

  def teardown
    begin
      @user.force_delete
    rescue
    end
  end

  test "show and list gear groups" do
    get :index , {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    body = JSON.parse(@response.body)
    id = body["data"][0]["id"]
    supported_api_versions = body['supported_api_versions']
    supported_api_versions.each do |version|
      @request.env['HTTP_ACCEPT'] = "application/json; version=#{version}"
      get :index , {"domain_id" => @domain.namespace, "application_id" => @app.name}
      assert_response :success
      @request.env['HTTP_ACCEPT'] = "application/xml; version=#{version}"
      get :index , {"domain_id" => @domain.namespace, "application_id" => @app.name}
      assert_response :success
    end

    @request.env['HTTP_ACCEPT'] = 'application/json'
    get :show, {"id" => id, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success

    get :index , {"application_id" => @app.id}
    assert_response :success
    body = JSON.parse(@response.body)
    id = body["data"][0]["id"]
    get :show, {"id" => id, "application_id" => @app.id}
    assert_response :success
  end

  test "no or non-existent app name" do
    get :index , {"domain_id" => @domain.namespace}
    assert_response :not_found
    get :show, {"domain_id" => @domain.namespace}
    assert_response :not_found

    get :index , {"domain_id" => @domain.namespace, "application_id" => "bogus"}
    assert_response :not_found
    get :show, {"domain_id" => @domain.namespace, "application_id" => "bogus"}
    assert_response :not_found
  end

  test "no or non-existent domain id" do
    get :index , {"application_id" => @app.name}
    assert_response :not_found
    get :show, {"application_id" => @app.name}
    assert_response :not_found

    get :index , {"application_id" => @app.name, "domain_id" => "bogus"}
    assert_response :not_found
    get :show, {"application_id" => @app.name, "domain_id" => "bogus"}
    assert_response :not_found

  end

  test "no or non-existent app id" do
    get :index 
    assert_response :not_found
    get :show
    assert_response :not_found

    get :index , {"application_id" => "1234"}
    assert_response :not_found
    get :show, {"application_id" => "1234"}
    assert_response :not_found
  end

  test "no gear id" do
    get :show , {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :not_found
    get :show, {"id" => "bogus", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :not_found

    get :show , {"application_id" => @app.id}
    assert_response :not_found
    get :show, {"id" => "bogus", "application_id" => @app.id}
    assert_response :not_found
  end

  test "get gear groups in all versions" do
    get :index , {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert supported_api_versions = json['supported_api_versions']
    supported_api_versions.each do |version|
      @request.env['HTTP_ACCEPT'] = "application/json; version=#{version}"
      get :show, {"id" => json["data"][0]["id"], "domain_id" => @domain.namespace, "application_id" => @app.name}
      assert_response :ok, "Getting gear groups for version #{version} failed"
    end
    @request.env['HTTP_ACCEPT'] = "application/json"
  end

end
