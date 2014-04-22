ENV["TEST_NAME"] = "functional_descriptors_controller_test"
require 'test_helper'
class DescriptorsControllerTest < ActionController::TestCase

  def setup
    @controller = DescriptorsController.new

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
    @app = Application.create_app(@app_name, cartridge_instances_for(:php), @domain, :scalable => true)
    @app.save
  end

  def teardown
    begin
      @user.force_delete
    rescue
    end
  end

  test "show" do
    get :show, {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success

    @request.env['HTTP_ACCEPT'] = 'application/xml'
    get :show, {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    @request.env['HTTP_ACCEPT'] = 'application/json'
  end

  test "no app or domain id" do
    get :show, {"application_id" => @app.name}
    assert_response :not_found
    get :show, {"domain_id" => @domain.namespace}
    assert_response :not_found
  end

  test "get descriptor in all versions" do
    get :show, {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert supported_api_versions = json['supported_api_versions']
    supported_api_versions.each do |version|
      @request.env['HTTP_ACCEPT'] = "application/json; version=#{version}"
      get :show, {"domain_id" => @domain.namespace, "application_id" => @app.name}
      assert_response :ok, "Getting descriptor for version #{version} failed"
    end
    @request.env['HTTP_ACCEPT'] = "application/json"
  end
end
