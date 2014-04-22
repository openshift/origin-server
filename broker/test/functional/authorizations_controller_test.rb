ENV["TEST_NAME"] = "functional_authorizations_controller_test"
require 'test_helper'
require 'openshift-origin-controller'
require 'mocha/setup'

class AuthorizationsControllerTest < ActionController::TestCase

  def setup
    @controller = AuthorizationsController.new

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

  end

  def teardown
    begin
      @user.force_delete
    rescue
    end
  end

  test "authorization create show update destroy and list" do  
    post :create, {"expires_in" => 60, "scope" => "session", "reuse" => true}
    assert_response :created
    body = JSON.parse(@response.body)
    id = body["data"]["id"]

    post :create, {"expires_in" => 60, "scope" => "userinfo", "reuse" => true}
    assert_response :created
    body = JSON.parse(@response.body)
    id2 = body["data"]["id"]

    post :create, {"expires_in" => 60, "scope" => "read", "reuse" => true}
    assert_response :created
    body = JSON.parse(@response.body)
    id3 = body["data"]["id"]

    get :show , {"id" =>  id}
    assert_response :success
    @request.env['HTTP_ACCEPT'] = 'application/xml'
    get :show , {"id" =>  id}
    assert_response :success
    @request.env['HTTP_ACCEPT'] = 'application/json'
    put :update , {"id" =>  id, "note" => "testing update"}
    assert_response :success
    get :index , {}
    assert_response :success

    delete :destroy , {"id" =>  id}
    assert_response :ok
    get :show , {"id" =>  id}
    assert_response :not_found
    get :show , {"id" =>  id2}
    assert_response :success
    get :show , {"id" =>  id3}
    assert_response :success

    delete :destroy_all, {:scope => "bogus"}
    assert_response :ok
    get :show , {"id" =>  id2}
    assert_response :success
    get :show , {"id" =>  id3}
    assert_response :success

    delete :destroy_all, {:scope => "userinfo"}
    assert_response :ok
    get :show , {"id" =>  id2}
    assert_response :not_found
    get :show , {"id" =>  id3}
    assert_response :success

    delete :destroy_all 
    assert_response :ok
    get :show , {"id" =>  id3}
    assert_response :not_found
  end

  test "invalid id" do
    get :show
    assert_response :not_found
    put :update
    assert_response :not_found
    delete :destroy 
    assert_response :ok
  end

  test "get authorization in all versions" do
    post :create, {"expires_in" => 60, "scope" => "session", "reuse" => true}
    assert_response :created
    assert json = JSON.parse(response.body)
    assert supported_api_versions = json['supported_api_versions']
    supported_api_versions.each do |version|
      @request.env['HTTP_ACCEPT'] = "application/json; version=#{version}"
      get :show , {"id" =>  json['data']['id']}
      assert_response :ok, "Getting authorization for version #{version} failed"
    end
    @request.env['HTTP_ACCEPT'] = "application/json"
  end

end
