ENV["TEST_NAME"] = "functional_applications_controller_test"
require 'test_helper'
class ApplicationControllerTest < ActionController::TestCase
  
  def setup
    @controller = ApplicationsController.new
        
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
  end
  
  def teardown
    begin
      @user.force_delete
    rescue
    end
  end
  
  test "app create show list and destory" do
    @app_name = "app#{@random}"
    post :create, {"name" => @app_name, "cartridge" => PHP_VERSION, "domain_id" => @domain.namespace}
    assert_response :created
    get :show, {"id" => @app_name, "domain_id" => @domain.namespace}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert link = json['data']['links']['ADD_CARTRIDGE']
    assert_equal Rails.configuration.openshift[:download_cartridges_enabled], link['optional_params'].one?{ |p| p['name'] == 'url' }

    get :index , {"domain_id" => @domain.namespace}
    assert_response :success
    delete :destroy , {"id" => @app_name, "domain_id" => @domain.namespace}
    assert_response :ok
  end
  
  test "no app id" do
    post :create, {"domain_id" => @domain.namespace}
    assert_response :unprocessable_entity
    get :show, {"domain_id" => @domain.namespace}
    assert_response :not_found
    delete :destroy , {"domain_id" => @domain.namespace}
    assert_response :not_found
  end
  
  test "no domain id" do
    @app_name = "app#{@random}"
    post :create, {"id" => @app_name}
    assert_response :not_found
    get :show, {"id" => @app_name}
    assert_response :not_found
    get :index , {"id" => @app_name}
    assert_response :not_found
    delete :destroy , {"id" => @app_name}
    assert_response :not_found
  end
  
  test "no web_framework cartridge or too many" do
    @app_name = "app#{@random}"
    post :create, {"name" => @app_name, "domain_id" => @domain.namespace}
    assert_response :unprocessable_entity
    post :create, {"name" => @app_name, "cartridges" => "mysql-5.1", "domain_id" => @domain.namespace}
    assert_response :unprocessable_entity
    post :create, {"name" => @app_name, "cartridges" => [PHP_VERSION, "ruby-1.9"], "domain_id" => @domain.namespace}
    assert_response :unprocessable_entity
  end
end
