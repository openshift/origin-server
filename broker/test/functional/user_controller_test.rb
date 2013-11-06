ENV["TEST_NAME"] = "functional_user_controller_test"
require 'test_helper'
class UserControllerTest < ActionController::TestCase

  def setup
    @controller = UserController.new

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
  end

  def teardown
    begin
      @user.force_delete
    rescue
    end
  end

  test "show and delete" do
    get :show
    assert_response :success
    delete :destroy
    assert_response :forbidden
  end

  test "get user in all versions" do
    get :show
    assert_response :success
    assert json = JSON.parse(response.body)
    assert supported_api_versions = json['supported_api_versions']
    supported_api_versions.each do |version|
      @request.env['HTTP_ACCEPT'] = "application/json; version=#{version}"
      get :show
      assert_response :ok, "Getting user for version #{version} failed"
    end
  end
end
