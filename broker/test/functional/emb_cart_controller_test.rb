ENV["TEST_NAME"] = "functional_emb_cart_controller_test"
require 'test_helper'
class EmbCartControllerTest < ActionController::TestCase
  
  def setup
    @controller = EmbCartController.new
    
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
    @app = Application.create_app(@app_name, [PHP_VERSION], @domain)
    @app.save
  end
  
  def teardown
    begin
      @user.force_delete
    rescue
    end
  end
  
  test "embedded cartridge create show list and destory by domain and app name" do
    name = MYSQL_VERSION
    post :create, {"name" => name, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :created
    get :show, {"id" => name, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    get :index , {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    delete :destroy , {"id" => name, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
  end
  
  test "embedded cartridge create show list and destory by app id" do
    name = MYSQL_VERSION
    post :create, {"name" => name, "application_id" => @app.id}
    assert_response :created
    get :show, {"id" => name, "application_id" => @app.id}
    assert_response :success
    get :index , {"application_id" => @app.id}
    assert_response :success
    delete :destroy , {"id" => name, "application_id" => @app.id}
    assert_response :success
  end
  
  test "no app name" do
    name = MYSQL_VERSION
    post :create, {"name" => name, "domain_id" => @domain.namespace}
    assert_response :not_found
    get :show, {"id" => name, "domain_id" => @domain.namespace}
    assert_response :not_found
    put :update, {"id" => name, "domain_id" => @domain.namespace, "additional_gear_storage" => 10}
    assert_response :not_found
    get :index , {"id" => name, "domain_id" => @domain.namespace}
    assert_response :not_found
    delete :destroy , {"id" => name, "domain_id" => @domain.namespace}
    assert_response :not_found
  end
  
  test "no app id" do
    name = MYSQL_VERSION
    post :create, {"name" => name}
    assert_response :not_found
    get :show, {"id" => name}
    assert_response :not_found
    put :update, {"id" => name, "additional_gear_storage" => 10}
    assert_response :not_found
    get :index , {"id" => name}
    assert_response :not_found
    delete :destroy , {"id" => name}
    assert_response :not_found
  end
  
  test "no domain id" do
    name = MYSQL_VERSION
    post :create, {"name" => name, "application_id" => @app.name}
    assert_response :not_found
    get :show, {"id" => name, "application_id" => @app.name}
    assert_response :not_found
    put :update, {"id" => name, "application_id" => @app.name, "additional_gear_storage" => 10}
    assert_response :not_found
    get :index , {"id" => name, "application_id" => @app.name}
    assert_response :not_found
    delete :destroy , {"id" => name, "application_id" => @app.name}
    assert_response :not_found
  end
  
  test "no cartridge id by domain and app name" do
    post :create, {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :unprocessable_entity
    get :show, {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :not_found
    put :update, {"domain_id" => @domain.namespace, "application_id" => @app.name, "additional_gear_storage" => 10}
    assert_response :not_found
    delete :destroy , {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :not_found
  end
  
  test "no cartridge id by app id" do
    post :create, {"application_id" => @app.id}
    assert_response :unprocessable_entity
    get :show, {"application_id" => @app.id}
    assert_response :not_found
    put :update, {"application_id" => @app.id, "additional_gear_storage" => 10}
    assert_response :not_found
    delete :destroy , {"application_id" => @app.id}
    assert_response :not_found
  end
  
  test "invalid cartridge id by domain and app name" do
    post :create, {"domain_id" => @domain.namespace, "application_id" => @app.name, "name" => "bogus"}
    assert_response :unprocessable_entity
    get :show, {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :not_found
    put :update, {"domain_id" => @domain.namespace, "application_id" => @app.name, "additional_gear_storage" => 10}
    assert_response :not_found
    delete :destroy , {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :not_found
  end
  
  test "invalid cartridge id by app id" do
    post :create, {"application_id" => @app.id}
    assert_response :unprocessable_entity
    get :show, {"application_id" => @app.id}
    assert_response :not_found
    put :update, {"application_id" => @app.id, "additional_gear_storage" => 10}
    assert_response :not_found
    delete :destroy , {"application_id" => @app.id}
    assert_response :not_found
  end
  
  test "destroy web_framework cartridge" do
    delete :destroy , {"id" => PHP_VERSION, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :unprocessable_entity
    delete :destroy , {"id" => PHP_VERSION, "application_id" => @app.id}
    assert_response :unprocessable_entity
  end
  
end
