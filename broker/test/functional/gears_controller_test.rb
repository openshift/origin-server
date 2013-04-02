ENV["TEST_NAME"] = "functional_gears_controller_test"
require 'test_helper'
require 'openshift-origin-controller'
require 'mocha'

class GearsControllerTest < ActionController::TestCase
  
  def setup
    @controller = GearsController.new
    
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
  
  test "show and list gear groups" do
    get :index , {}
    assert_response :moved_permanently
    get :show, {}
    assert_response :moved_permanently
  end
end
