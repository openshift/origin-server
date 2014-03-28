ENV["TEST_NAME"] = "functional_dns_resolvable_controller_test"
require 'test_helper'
class DnsResolvableControllerTest < ActionController::TestCase

  def setup
    @controller = DnsResolvableController.new

    @random = rand(1000000000)
    @login = "user#{@random}"
    @password = "password"
    @user = CloudUser.new(login: @login)
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
    @app = Application.create_app(@app_name, cartridge_instances_for(:php), @domain)
    @app.save
  end

  def teardown
    begin
      @user.force_delete
    rescue
    end
  end

  test "get dns resolvable" do
    get :show, {"application_id" => @app.name, "domain_id" => @domain.namespace}
    assert_response :not_found
    get :show, {"application_id" => @app.id}
    assert_response :not_found
  end

  test "no app or domain id" do
    get :show, {"domain_id" => @domain.namespace}
    assert_response :not_found
    get :show, {"id" => @app_name}
    assert_response :not_found
  end
end
