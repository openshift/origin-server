ENV["TEST_NAME"] = "functional_emb_cart_controller_test"
require 'test_helper'
class EmbCartControllerTest < ActionController::TestCase

  def setup
    @controller = EmbCartController.new

    @random = rand(1000000000)
    @login = "user#{@random}"
    @password = "password"
    @user = CloudUser.new(login: @login)
    @user.private_ssl_certificates = true
    @user.save
    Lock.create_lock(@user)
    register_user(@login, @password)

    @request.env['HTTP_AUTHORIZATION'] = "Basic " + Base64.encode64("#{@login}:#{@password}")
    @request.env['REMOTE_USER'] = @login
    @request.env['HTTP_ACCEPT'] = "application/json"
    stubber
    @namespace = "ns#{@random}"
    @domain = Domain.new(namespace: @namespace, owner: @user)
    @domain.save
    @app_name = "app#{@random}"
    (@app = Application.new(name: @app_name, domain: @domain)).add_initial_cartridges(cartridge_instances_for(:php))
  end

  def teardown
    @user.force_delete rescue nil
  end

  test "embedded cartridge create show list and destroy by domain and app name" do
    name = mysql_version
    post :create, {"name" => name, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :created
    get :show, {"id" => name, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    get :index , {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    delete :destroy , {"id" => name, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
  end

  test "embedded cartridge create show list and destroy by app id" do
    name = mysql_version
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
    name = mysql_version
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
    name = mysql_version
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
    name = mysql_version
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
    delete :destroy , {"id" => php_version, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :unprocessable_entity
    delete :destroy , {"id" => php_version, "application_id" => @app.id}
    assert_response :unprocessable_entity
  end

  test "get embedded cartridge in all versions" do
    name = mysql_version
    post :create, {"name" => name, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :created
    assert json = JSON.parse(response.body)
    assert supported_api_versions = json['supported_api_versions']
    supported_api_versions.each do |version|
      @request.env['HTTP_ACCEPT'] = "application/json; version=#{version}"
      get :show, {"id" => name, "domain_id" => @domain.namespace, "application_id" => @app.name}
      assert_response :ok, "Getting embedded cartridge for version #{version} failed"
    end
  end

  def test_attempt_to_add_obsolete_cartridge
    Rails.cache.clear
    carts = []
    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "redhat"
    cart.name = "emb-cart-1.0"
    cart.provides = ["emb"]
    cart.version = "1.0"
    cart.obsolete = true
    cart.categories = ["embedded"]
    carts << cart

    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "redhat"
    cart.name = "emb-cart-1.0"
    cart.provides = ["emb"]
    cart.version = "1.1"
    cart.categories = ["embedded"]
    carts << cart
    CartridgeCache.stubs(:get_all_cartridges).returns(carts)

    post :create, {"name" => "emb-cart-1.0", "application_id" => @app.id}
    assert_response :unprocessable_entity
  ensure
    Rails.cache.clear
  end
end
