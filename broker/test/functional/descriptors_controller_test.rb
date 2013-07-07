ENV["TEST_NAME"] = "functional_descriptors_controller_test"
require 'test_helper'
class DescriptorsControllerTest < ActionController::TestCase
  
  def setup
    @controller = DescriptorsController.new
    
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
    @namespace = "ns#{@random}"
    @domain = Domain.new(namespace: @namespace, owner:@user)
    @domain.save
    @app_name = "app#{@random}"
    @app = Application.create_app(@app_name, [PHP_VERSION], @domain, nil, true)
    @app.save
  end
  
  def teardown
    begin
      @user.force_delete
    rescue
    end
  end
  
  test "show" do
    get :show, {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
  end
  
  test "no app or domain id" do
    get :show, {"application_id" => @app.name}
    assert_response :not_found
    get :show, {"domain_id" => @domain.namespace}
    assert_response :not_found
  end
end
