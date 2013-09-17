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

  test "app create show list update and destroy by domain and app name" do
    @app_name = "app#{@random}"
    post :create, {"name" => @app_name, "cartridge" => PHP_VERSION, "domain_id" => @domain.namespace}
    assert_response :created
    get :show, {"id" => @app_name, "domain_id" => @domain.namespace}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert link = json['data']['links']['ADD_CARTRIDGE']
    assert_equal Rails.configuration.openshift[:download_cartridges_enabled], link['optional_params'].one?{ |p| p['name'] == 'url' }

    get :index, {"domain_id" => @domain.namespace}
    assert_response :success

    put :update, {"id" => @app_name,
                  "domain_id" => @domain.namespace,
                  "auto_deploy" => false,
                  "keep_deployments" => 2,
                  "deployment_type" => 'binary',
                  "deployment_branch" => 'stage'
                 }
    assert_response :success
    
    get :show, {"id" => @app_name, "domain_id" => @domain.namespace}
    assert_response :success
    assert json = JSON.parse(response.body)
    #TODO uncomment once save to mongo is fixed
    assert_equal json['data']['auto_deploy'], false 
    assert_equal json['data']['keep_deployments'], 2
    assert_equal json['data']['deployment_type'], 'binary'
    assert_equal json['data']['deployment_branch'], 'stage'
    

    delete :destroy, {"id" => @app_name, "domain_id" => @domain.namespace}
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

  test "list applications in a non-lowercased domain" do
    Domain.find_or_create_by(namespace: "abcD", owner: @user)
    get :index, :domain_id => 'abcD'
    assert_response :success
  end

  test "attempt to create and update without create_application permission" do
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

    scopes.clear << Scope::Session.new
    @domain.members.find(@user).role = :view
    @domain.save; @domain.run_jobs

    put :update, {"name" => @app_name, "domain_id" => @domain.namespace, "auto_deploy" => false}
    assert_response :forbidden

    @domain.members.find(@user).role = :edit
    @domain.save; @domain.run_jobs

    put :update, {"name" => @app_name, "domain_id" => @domain.namespace, "auto_deploy" => false}
    assert_response :success
  end

  test "attempt to create with only build scope" do
    @app_name = "app#{@random}"
    post :create, {"name" => @app_name, "cartridge" => PHP_VERSION, "domain_id" => @domain.namespace}
    assert_response :created
    app = assigns(:application)

    CloudUser.any_instance.stubs(:scopes).returns(Scope::Scopes.new << Scope::DomainBuilder.new(app))

    # allows creation of a builder
    @app_name = "appx#{@random}"
    post :create, {"name" => @app_name, "cartridge" => PHP_VERSION, "domain_id" => @domain.namespace}
    assert_response :created
    builder_app = assigns(:application)
    # records that the builder is associated
    assert_equal builder_app.builder_id, app._id
    assert_equal builder_app.builder, app
  end

  test "attempt to create when all gear sizes are disabled" do
    Domain.any_instance.stubs(:allowed_gear_sizes).returns([])

    @app_name = "app#{@random}"
    post :create, {"name" => @app_name, "cartridge" => PHP_VERSION, "domain_id" => @domain.namespace}
    assert_response :forbidden
    assert json = JSON.parse(response.body)
    assert_nil json['messages'][0]['field']
    assert json['messages'][0]['text'] =~ /disabled all gear sizes from being created/
    assert_equal 134, json['messages'][0]['exit_code']
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

  test "invalid updates" do
    @app_name = "app#{@random}"
    post :create, {"name" => @app_name, "cartridge" => PHP_VERSION, "domain_id" => @domain.namespace}
    assert_response :created
    
    put :update, {"id" => @app_name,
                  "domain_id" => @domain.namespace
                 }
    assert_response :unprocessable_entity
    
    put :update, {"id" => @app_name,
                  "domain_id" => @domain.namespace,
                  "auto_deploy" => 'blah'
                 }
    assert_response :unprocessable_entity

    put :update, {"id" => @app_name,
                  "domain_id" => @domain.namespace,
                  "keep_deployments" => 'blah'
                 }
    assert_response :unprocessable_entity

    put :update, {"id" => @app_name,
                  "domain_id" => @domain.namespace,
                  "deployment_type" => 'blah'
                 }
    assert_response :unprocessable_entity

    put :update, {"id" => @app_name,
                  "domain_id" => @domain.namespace,
                  "deployment_branch" => 'abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghiabcdefghi'
                 }
    assert_response :unprocessable_entity
  end

  test "get application in all version" do
    @app_name = "app#{@random}"
    post :create, {"name" => @app_name, "cartridge" => PHP_VERSION, "domain_id" => @domain.namespace}
    assert_response :created
    assert json = JSON.parse(response.body)
    assert supported_api_versions = json['supported_api_versions']
    supported_api_versions.each do |version|
      @request.env['HTTP_ACCEPT'] = "application/json; version=#{version}"
      get :show, {"id" => @app_name, "domain_id" => @domain.namespace}
      assert_response :ok, "Getting application for version #{version} failed"
    end
  end
end
