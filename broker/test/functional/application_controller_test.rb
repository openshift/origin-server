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
  
  test "app create show list and destroy by domain and app name" do
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
  
  test "app create show list and destroy by app id" do
    @app_name = "app#{@random}"
    post :create, {"name" => @app_name, "cartridge" => PHP_VERSION, "domain_id" => @domain.namespace}
    assert_response :created
    assert json = JSON.parse(response.body)
    assert link = json['data']['id']
    app_id =  json['data']['id']
    
    get :show, {"id" => app_id}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert link = json['data']['links']['ADD_CARTRIDGE']
    assert_equal Rails.configuration.openshift[:download_cartridges_enabled], link['optional_params'].one?{ |p| p['name'] == 'url' }

    get :index 
    assert_response :success
    
    delete :destroy , {"id" => app_id}
    assert_response :ok
  end
  
  test "attempt to create without create_application permission" do
    @app_name = "app#{@random}"
    scopes = Scope::Scopes.new
    CloudUser.any_instance.stubs(:scopes).returns(scopes << Scope::Read.new)
    post :create, {"name" => @app_name, "cartridge" => PHP_VERSION, "domain_id" => @domain.namespace}
    assert_response :forbidden

    @app_name = "app#{@random}"
    scope = Scope::Session.new
    scope.expects(:authorize_action?).at_least(3).returns(false)
    scopes.clear << scope

    post :create, {"name" => @app_name, "cartridge" => PHP_VERSION, "domain_id" => @domain.namespace}
    assert_response :forbidden

    scopes.clear << Scope::Session.new
    @domain.members.find(@user).role = :view
    @domain.save; @domain.run_jobs

    post :create, {"name" => @app_name, "cartridge" => PHP_VERSION, "domain_id" => @domain.namespace}    
    assert_response :forbidden

    @domain.members.find(@user).role = :edit
    @domain.save; @domain.run_jobs

    post :create, {"name" => @app_name, "cartridge" => PHP_VERSION, "domain_id" => @domain.namespace}    
    assert_response :success    
  end

  test "attempt to create with only build scope" do
    @app_name = "app#{@random}"
    post :create, {"name" => @app_name, "cartridge" => PHP_VERSION, "domain_id" => @domain.namespace}
    assert_response :created
    app = assigns(:application)

    CloudUser.any_instance.stubs(:scopes).returns(Scope::Scopes.new << Scope::Application.new(:id => app._id, :app_scope => :build))

    # prohibits non matching cartridges
    @app_name = "appx#{@random}"
    post :create, {"name" => @app_name, "cartridge" => RUBY_VERSION, "domain_id" => @domain.namespace}
    assert_response :forbidden

    # allows creation of the same builder type
    @app_name = "appx#{@random}"
    post :create, {"name" => @app_name, "cartridge" => PHP_VERSION, "domain_id" => @domain.namespace}
    $g = 1
    assert_response :created    
  end

  test "invalid or empty app name or id" do
    # no name
    post :create, {"domain_id" => @domain.namespace}
    assert_response :unprocessable_entity
    # name with dashes
    post :create, {"domain_id" => @domain.namespace, "name" => "abcd-1234", "cartridge" => PHP_VERSION}
    assert_response :unprocessable_entity
    # name already exists
    @app_name = "app#{@random}"
    post :create, {"name" => @app_name, "cartridge" => PHP_VERSION, "domain_id" => @domain.namespace}
    assert_response :created
    post :create, {"name" => @app_name, "cartridge" => PHP_VERSION, "domain_id" => @domain.namespace}
    assert_response :unprocessable_entity
    
    get :show, {"domain_id" => @domain.namespace}
    assert_response :not_found
    get :show
    assert_response :not_found
    delete :destroy , {"domain_id" => @domain.namespace}
    assert_response :not_found
    delete :destroy
    assert_response :not_found
  end
  
  test "no domain id" do
    @app_name = "app#{@random}"
    post :create, {"id" => @app_name}
    assert_response :not_found
    get :show, {"id" => @app_name}
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
