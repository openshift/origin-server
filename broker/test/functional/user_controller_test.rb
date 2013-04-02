ENV["TEST_NAME"] = "functional_user_controller_test"
require 'test_helper'
class UserControllerTest < ActionController::TestCase
  
  def setup
    @controller = UserController.new
    
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
    stubber
  end
  
  def teardown
    begin
      @user.force_delete
    rescue
    end
  end
  
  test "show and delete" do
    get :show
    assert_response :success
    delete :destroy
    assert_response :forbidden
  end
end