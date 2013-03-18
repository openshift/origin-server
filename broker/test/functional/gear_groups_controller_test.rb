ENV["TEST_NAME"] = "functional_gear_groups_controller_test"
require 'test_helper'
require 'openshift-origin-controller'
require 'mocha'

class GearGroupsControllerTest < ActionController::TestCase
  
  def setup
    @controller = GearGroupsController.new
    
    @random = rand(1000000000)
    @login = "user#{@random}"
    @user = CloudUser.new(login: @login)
    @user.capabilities["private_ssl_certificates"] = true
    @user.save
    Lock.create_lock(@user)
    
    @request.env['HTTP_AUTHORIZATION'] = "Basic " + Base64.encode64("#{@login}:password")
    @request.env['HTTP_ACCEPT'] = "application/json"
    stubber
    @namespace = "ns#{@random}"
    @domain = Domain.new(namespace: @namespace, owner:@user)
    @domain.save
    @app_name = "app#{@random}"
    @app = Application.create_app(@app_name, ["php-5.3"], @domain, "small")
    @app.save
  end
  
  def teardown
    begin
      @user.force_delete
    rescue
    end
  end
  
  test "show and list gear groups" do
    get :index , {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    #get :show, {"id" => name, "domain_id" => @domain.namespace, "application_id" => @app.name}
    #assert_response :success
  end

  test "no app id" do
    get :index , {"domain_id" => @domain.namespace}
    assert_response :not_found
    #get :show, {"id" => name, "domain_id" => @domain.namespace}
    #assert_response :not_found
  end
  
  test "no domain id" do
    get :index , {"application_id" => @app.name}
    assert_response :not_found
    #get :show, {"id" => name, "application_id" => @app.name}
    #assert_response :not_found
  end


end
