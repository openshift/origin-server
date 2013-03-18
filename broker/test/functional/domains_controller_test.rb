ENV["TEST_NAME"] = "functional_domains_controller_test"
require 'test_helper'
class DomiansControllerTest < ActionController::TestCase
  
  def setup
    @controller = DomainsController.new
    
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
  
  test "domain create show list and destory" do
    namespace = "ns#{@random}"
    post :create, {"id" => namespace}
    assert_response :created
    get :show, {"id" => namespace}
    assert_response :success
    get :index , {}
    assert_response :success
    new_namespace = "xns#{@random}"
    put :update, {"existing_id" => namespace, "id" => new_namespace}
    assert_response :success
    delete :destroy , {"id" => new_namespace}
    assert_response :no_content
  end
  
  
  test "no or non-existent domain id" do
    post :create, {}
    assert_response :unprocessable_entity
    get :show, {}
    assert_response :not_found
    new_namespace = "xns#{@random}"
    put :update , {"id" => new_namespace}
    assert_response :not_found
    delete :destroy , {}
    assert_response :not_found
    
    get :show, {"id" => "bogus"}
    assert_response :not_found
    new_namespace = "xns#{@random}"
    put :update , {"existing_id" => "bogus", "id" => new_namespace}
    assert_response :not_found
    delete :destroy , {"id" => "bogus"}
    assert_response :not_found
  end
  
  test "delete domain with apps" do
    namespace = "ns#{@random}"
    domain = Domain.new(namespace: namespace, owner:@user)
    domain.save
    
    app_name = "app#{@random}"
    app = Application.create_app(app_name, [PHP_VERSION], domain, "small")
    app.save
    
    delete :destroy , {"id" => namespace}
    assert_response :unprocessable_entity
    
    delete :destroy , {"id" => namespace, "force" => true}
    assert_response :no_content
  end
  
  test "update domain with apps" do
    namespace = "ns#{@random}"
    domain = Domain.new(namespace: namespace, owner:@user)
    domain.save
    
    app_name = "app#{@random}"
    app = Application.create_app(app_name, [PHP_VERSION], domain, "small")
    app.save
    
    new_namespace = "xns#{@random}"
    put :update, {"existing_id" => namespace, "id" => new_namespace}
    assert_response :unprocessable_entity
    
    app.destroy_app
    
    put :update, {"existing_id" => namespace, "id" => new_namespace}
    assert_response :success
    get :show, {"id" => new_namespace}
    assert_response :success
  end
end
