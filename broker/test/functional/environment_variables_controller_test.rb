ENV["TEST_NAME"] = "functional_environment_variable_controller_test"
require 'test_helper'
class EnvironmentVariablesControllerTest < ActionController::TestCase

  def setup
    @controller = EnvironmentVariablesController.new

    @random = rand(1000000000)
    @login = "user#{@random}"
    @password = 'password'
    @user = CloudUser.new(login: @login)
    @user.save
    Lock.create_lock(@user.id)
    register_user(@login, @password)

    @request.env['HTTP_AUTHORIZATION'] = "Basic " + Base64.encode64("#{@login}:#{@password}")
    @request.env['REMOTE_USER'] = @login
    @request.env['HTTP_ACCEPT'] = "application/json"
    stubber
    result_io = ResultIO.new
    result_io.resultIO.string = '{}'
    @container.stubs(:list_user_env_vars).returns(result_io)
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

  test "environment_variable create show list update and destroy" do
    post :create, {"name" => "foo", "value" => "bar", "application_id" => @app._id}
    assert_response :created

    result_io = ResultIO.new
    result_io.resultIO.string = '{"foo":"bar"}'
    @container.stubs(:list_user_env_vars).returns(result_io)
    assert json = JSON.parse(response.body)
    assert supported_api_versions = json['supported_api_versions']
    supported_api_versions.each do |version|
      @request.env['HTTP_ACCEPT'] = "application/json; version=#{version}"
      get :show, {"id" => "foo", "application_id" => @app._id}
      assert_response :success

      @request.env['HTTP_ACCEPT'] = "application/xml; version=#{version}"
      get :show, {"id" => "foo", "application_id" => @app._id}
      assert_response :success
    end
    @request.env['HTTP_ACCEPT'] = 'application/json'

    get :index , {"application_id" => @app._id}
    assert_response :success

    get :update, {"id" => "foo", "value" => "barX", "application_id" => @app._id}
    assert_response :success

    get :destroy, {"id" => "foo", "application_id" => @app._id}
    assert_response :success

  end

  test "no or non-existent environment_variable" do
    get :show, {"application_id" => @app.id}
    assert_response :not_found
    get :show, {"application_id" => @app.id, "id" => "bogus"}
    assert_response :not_found
  end

  test "attempt to create invalid environment_variable" do
    post :create, {"name" => "1foo", "value" => "bar", "application_id" => @app._id}
    assert_response :unprocessable_entity

    post :create, {"name" => "foo-bad", "value" => "bar", "application_id" => @app._id}
    assert_response :unprocessable_entity

    post :create, {"name" => ".foo", "value" => "bar", "application_id" => @app._id}
    assert_response :unprocessable_entity

    post :create, {"name" => "foo bad", "value" => "bar", "application_id" => @app._id}
    assert_response :unprocessable_entity

    post :create, {"name" => "foo\xB3", "value" => "bar", "application_id" => @app._id}
    assert_response :bad_request

    post :create, {"name" => "foo", "value" => "bar\255", "application_id" => @app._id}
    assert_response :bad_request
    
    post :create, {"name" => "foo", "value" => "\\000TEST", "application_id" => @app._id}
    assert_response :unprocessable_entity

  end

end
