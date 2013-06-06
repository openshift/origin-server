ENV["TEST_NAME"] = "functional_emb_cart_events_controller_test"
require 'test_helper'
class EmbCartEventsControllerTest < ActionController::TestCase
  
  def setup
    @controller = EmbCartEventsController.new
    
    @random = rand(1000000000)
    @login = "user#{@random}"
    @user = CloudUser.new(login: @login)
    @password = "password"
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
    @cartridge_id = MYSQL_VERSION
    @app = Application.create_app(@app_name, [PHP_VERSION, @cartridge_id], @domain, "small")
    @app.save
  end
  
  def teardown
    begin
      @user.force_delete
    rescue
    end
  end
  
  test "cartridge events" do
    post :create, {"event" => "stop", "domain_id" => @domain.namespace, "application_id" => @app.name, "cartridge_id" => @cartridge_id}
    assert_response :success
    post :create, {"event" => "start", "domain_id" => @domain.namespace, "application_id" => @app.name, "cartridge_id" => @cartridge_id}
    assert_response :success
    post :create, {"event" => "restart", "domain_id" => @domain.namespace, "application_id" => @app.name, "cartridge_id" => @cartridge_id}
    assert_response :success
    post :create, {"event" => "reload", "domain_id" => @domain.namespace, "application_id" => @app.name, "cartridge_id" => @cartridge_id}
    assert_response :success
  end
  
  test "no app domain or cartridge id" do
    post :create, {"event" => "stop", "application_id" => @app.name, "cartridge_id" => @cartridge_id}
    assert_response :not_found
    post :create, {"event" => "stop", "domain_id" => @domain.namespace, "cartridge_id" => @cartridge_id}
    assert_response :not_found
    post :create, {"event" => "stop", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :not_found
  end
  
  test "wrong event type" do
    post :create, {"event" => "bogus", "domain_id" => @domain.namespace, "application_id" => @app.name, "cartridge_id" => @cartridge_id}
    assert_response :unprocessable_entity
  end
end