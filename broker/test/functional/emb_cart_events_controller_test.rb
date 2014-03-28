ENV["TEST_NAME"] = "functional_emb_cart_events_controller_test"
require 'test_helper'
class EmbCartEventsControllerTest < ActionController::TestCase

  def setup
    @controller = allow_multiple_execution(EmbCartEventsController.new)

    @random = rand(1000000000)
    @login = "user#{@random}"
    @user = CloudUser.new(login: @login)
    @password = "password"
    @user.private_ssl_certificates = true
    @user.save
    Lock.create_lock(@user.id)
    register_user(@login, @password)

    @request.env['HTTP_AUTHORIZATION'] = "Basic " + Base64.encode64("#{@login}:#{@password}")
    @request.env['REMOTE_USER'] = @login
    @request.env['HTTP_ACCEPT'] = "application/json"
    stubber
    @namespace = "ns#{@random}"
    @domain = Domain.new(namespace: @namespace, owner:@user)
    @domain.save
    @app_name = "app#{@random}"
    @cartridge_id = mysql_version
    @app = Application.create_app(@app_name, cartridge_instances_for(:php, @cartridge_id), @domain)
    @app.save
  end

  def teardown
    begin
      @user.force_delete
    rescue
    end
  end

  test "cartridge events by domain and app name" do
    post :create, {"event" => "stop", "domain_id" => @domain.namespace, "application_id" => @app.name, "cartridge_id" => @cartridge_id}
    assert_response :success
    post :create, {"event" => "start", "domain_id" => @domain.namespace, "application_id" => @app.name, "cartridge_id" => @cartridge_id}
    assert_response :success
    post :create, {"event" => "restart", "domain_id" => @domain.namespace, "application_id" => @app.name, "cartridge_id" => @cartridge_id}
    assert_response :success
    post :create, {"event" => "reload", "domain_id" => @domain.namespace, "application_id" => @app.name, "cartridge_id" => @cartridge_id}
    assert_response :success
  end

  test "cartridge events" do
    post :create, {"event" => "stop", "application_id" => @app.id, "cartridge_id" => @cartridge_id}
    assert_response :success
    post :create, {"event" => "start", "application_id" => @app.id, "cartridge_id" => @cartridge_id}
    assert_response :success
    post :create, {"event" => "restart", "application_id" => @app.id, "cartridge_id" => @cartridge_id}
    assert_response :success
    post :create, {"event" => "reload", "application_id" => @app.id, "cartridge_id" => @cartridge_id}
    assert_response :success
  end

  test "no app domain or cartridge name and no app id" do
    post :create, {"event" => "stop", "application_id" => @app.name, "cartridge_id" => @cartridge_id}
    assert_response :not_found
    post :create, {"event" => "stop", "domain_id" => @domain.namespace, "cartridge_id" => @cartridge_id}
    assert_response :not_found
    post :create, {"event" => "stop", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :not_found
    post :create, {"event" => "stop", "cartridge_id" => @cartridge_id}
    assert_response :not_found
  end

  test "wrong event type" do
    post :create, {"event" => "bogus", "domain_id" => @domain.namespace, "application_id" => @app.name, "cartridge_id" => @cartridge_id}
    assert_response :unprocessable_entity
    post :create, {"event" => "bogus", "application_id" => @app.id, "cartridge_id" => @cartridge_id}
    assert_response :unprocessable_entity
  end
end
