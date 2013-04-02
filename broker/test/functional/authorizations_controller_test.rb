ENV["TEST_NAME"] = "functional_authorizations_controller_test"
require 'test_helper'
require 'openshift-origin-controller'
require 'mocha'

class AuthorizationsControllerTest < ActionController::TestCase
  
  def setup
    @controller = AuthorizationsController.new

    @random = rand(1000000000)
    @login = "user#{@random}"
    @password = "password"
    @user = CloudUser.new(login: @login)
    @user.capabilities["private_ssl_certificates"] = true
    @user.save
    Lock.create_lock(@user)
    register_user(@login, @password)
    
    @request.env['HTTP_AUTHORIZATION'] = "Basic " + Base64.encode64("#{@login}:#{@password}")
    @request.env['HTTP_ACCEPT'] = "application/json"

  end
  
  def teardown
    begin
      @user.force_delete
    rescue
    end
  end
  
  test "authrozation create show update destroy and list" do  
    post :create, {"expires_in" => 60, "scope" => "session", "reuse" => true}
    assert_response :created
    body = JSON.parse(@response.body)
    id = body["data"]["id"]
    get :show , {"id" =>  id}
    assert_response :success
    put :update , {"id" =>  id, "note" => "testing update"}
    assert_response :success
    get :index , {}
    assert_response :success
    delete :destroy , {"id" =>  id}
    assert_response :no_content
    delete :destroy_all 
    assert_response :no_content
  end
  
  test "invalid id" do
    get :show
    assert_response :not_found
    put :update
    assert_response :not_found
    delete :destroy 
    assert_response :no_content
  end
  
  
  
end
