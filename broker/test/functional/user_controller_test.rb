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
    @user.max_untracked_additional_storage = 1
    @user.save
    Lock.create_lock(@user.id)
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
    assert json = JSON.parse(response.body)
    assert supported_api_versions = json['supported_api_versions']
    supported_api_versions.each do |version|
      @request.env['HTTP_ACCEPT'] = "application/json; version=#{version}"
      get :show
      assert_response :success
      @request.env['HTTP_ACCEPT'] = "application/xml; version=#{version}"
      get :show
      assert_response :success
    end
    @request.env['HTTP_ACCEPT'] = 'application/json'
    delete :destroy
    assert_response :forbidden
  end

  test "show and delete sub account" do
    @user.parent_user_id = "1234"
    @user.save
    get :show
    assert_response :success
    assert json = JSON.parse(response.body)
    assert supported_api_versions = json['supported_api_versions']
    supported_api_versions.each do |version|
      @request.env['HTTP_ACCEPT'] = "application/json; version=#{version}"
      get :show
      assert_response :success
    end
    @request.env['HTTP_ACCEPT'] = 'application/json'
    delete :destroy
    assert_response :success
  end
end
