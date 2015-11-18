ENV["TEST_NAME"] = "functional_app_events_controller_test"
require 'test_helper'
class AppEventsControllerTest < ActionController::TestCase
  def setup
    @controller = allow_multiple_execution(AppEventsController.new)

    @random = rand(1000000000)
    @login = "user#{@random}"
    @password = "password"
    @user = CloudUser.new(login: @login)
    @user.private_ssl_certificates = true
    @user.max_gears = 10
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
    @cart = cartridge_instances_for(:php).first
    @app = Application.create_app(@app_name, [@cart], @domain, :scalable => true)
    @app.save

    d1 = Deployment.new(deployment_id: "1", ref: "mybranch", created_at: Time.now, activations: [Time.now.to_f])
    d2 = Deployment.new(deployment_id: "2", ref: "d975cbfd5c398610326c97f3988a52b208036eef", created_at: Time.now, activations: [Time.now.to_f])
    @app.update_deployments([d1, d2])
    @app.save
  end

  def teardown
    begin
      @user.force_delete
    rescue
    end
  end

  test "app events by domain name and app name" do
    post :create, {"event" => "stop", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    post :create, {"event" => "start", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    post :create, {"event" => "restart", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    post :create, {"event" => "force-stop", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success

    post :create, {"event" => "scale-down", "to" => "0", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :unprocessable_entity
    json_messages{ |a| assert a.any?{ |m| m['text'] =~ /Cannot scale down below gear limit of 1/ }, a.inspect }

    post :create, {"event" => "scale-up", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success, json_messages.inspect
    assert @app.reload.gears.count == 2

    post :create, {"event" => "scale-down", "by" => "2", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :unprocessable_entity
    json_messages{ |a| assert a.any?{ |m| m['text'] =~ /Cannot scale down below gear limit of 1/ }, a.inspect }

    post :create, {"event" => "scale-down", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    assert @app.reload.gears.count == 1

    post :create, {"event" => "scale-up", "to" => "2", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    assert @app.reload.gears.count == 2

    post :create, {"event" => "scale-down", "to" => "1", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    assert @app.reload.gears.count == 1

    post :create, {"event" => "scale-down", "by" => "-2", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    assert @app.reload.gears.count == 3

    post :create, {"event" => "scale-up", "by" => "-2", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    assert @app.reload.gears.count == 1

    post :create, {"event" => "reload", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success

    post :create, {"event" => "thread-dump", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :unprocessable_entity
    post :create, {"event" => "tidy", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    as = "as.#{@random}"
    post :create, {"event" => "add-alias", "alias" => as, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    post :create, {"event" => "remove-alias", "alias" => as, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    post :create, {"event" => "activate", "deployment_id" => "1", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
  end

  test "app events by app id" do
    post :create, {"event" => "stop", "application_id" => @app.id}
    assert_response :success
    post :create, {"event" => "start", "application_id" => @app.id}
    assert_response :success
    post :create, {"event" => "restart", "application_id" => @app.id}
    assert_response :success
    post :create, {"event" => "force-stop", "application_id" => @app.id}
    assert_response :success
    post :create, {"event" => "scale-up", "application_id" => @app.id}
    assert_response :success
    post :create, {"event" => "scale-down", "application_id" => @app.id}
    assert_response :success
    post :create, {"event" => "reload", "application_id" => @app.id}
    assert_response :success
    post :create, {"event" => "thread-dump", "application_id" => @app.id}
    assert_response :unprocessable_entity
    post :create, {"event" => "tidy", "application_id" => @app.id}
    assert_response :success
    as = "as.#{@random}"
    post :create, {"event" => "add-alias", "alias" => as, "application_id" => @app.id}
    assert_response :success
    post :create, {"event" => "remove-alias", "alias" => as, "application_id" => @app.id}
    assert_response :success
    post :create, {"event" => "activate", "deployment_id" => "1", "application_id" => @app.id}
    assert_response :success
  end

  test "make application HA" do
    @user.ha=true
    @user.save
    assert !@app.ha
    post :create, "event" => "make-ha", "application_id" => @app.id
    assert_response :success
    overrides = @app.reload.group_instances_with_overrides
    assert @app.ha
    assert_equal 1, overrides.length
    assert_equal 2, overrides[0].min_gears
    assert_equal(-1, overrides[0].max_gears)
    assert comp = overrides[0].components.detect{ |i| i.cartridge.is_web_proxy? }
    assert_equal 2, comp.min_gears
    assert_equal 0, comp.multiplier
  end

  test "enable and disable HA in application" do
    @user.ha=true
    @user.save
    assert !@app.ha
    post :create, "event" => "make-ha", "application_id" => @app.id
    assert_response :success
    post :create, "event" => "disable-ha", "application_id" => @app.id
    assert_response :success
    overrides = @app.reload.group_instances_with_overrides
    assert !@app.ha
    assert_equal 1, overrides.length
    assert_equal 1, overrides[0].min_gears
    assert_equal(-1, overrides[0].max_gears)
    assert comp = overrides[0].components.detect{ |i| i.cartridge.is_web_proxy? }
  end

  test "enable, scale up, and disable HA in application" do
    @user.ha=true
    @user.save
    assert !@app.ha
    post :create, "event" => "make-ha", "application_id" => @app.id
    assert_response :success
    application_controller, @controller = @controller, EmbCartController.new
    put :update, "scales_from" => "3", "scales_to" => "3", "application_id" => @app.id, "id" => @cart.name
    assert_response :success
    assert @app.reload.gears.count == 3
    @controller = application_controller
    post :create, "event" => "disable-ha", "application_id" => @app.id
    assert_response :success
    assert !@app.ha
    @app.group_overrides.each do |override|
      assert_empty(override.components.select do |c|
        c.class == ComponentOverrideSpec && c.name == "web_proxy" \
          && defined? c.min_gears
      end)
    end
  end

  test "no app name or domain name" do
    post :create, {"event" => "stop", "application_id" => @app.name}
    assert_response :not_found
    post :create, {"event" => "stop", "domain_id" => @domain.namespace}
    assert_response :not_found
  end

  test "no app id" do
    post :create, {"event" => "stop"}
    assert_response :not_found
  end

  test "no or wrong alias" do
    post :create, {"event" => "add-alias", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :unprocessable_entity
    post :create, {"event" => "remove-alias", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :unprocessable_entity
    post :create, {"event" => "remove-alias", "alias" => "bogus", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :not_found
  end

  test "wrong event type" do
    post :create, {"event" => "bogus", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :unprocessable_entity
  end

  test "thread-dump on a cartridge with threaddump hook" do
    #create an app with threaddump hook i.e. ruby-1.8 or jbossews-2.0
    app_name = "rubyapp#{@random}"
    ruby_app = Application.create_app(app_name, cartridge_instances_for(:ruby), @domain, :scalable => true)
    ruby_app.save
    post :create, {"event" => "thread-dump", "domain_id" => @domain.namespace, "application_id" => ruby_app.name}
    assert_response :success
  end
end
