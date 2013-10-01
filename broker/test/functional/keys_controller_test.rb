ENV["TEST_NAME"] = "functional_keys_controller_test"
require 'test_helper'
class KeysControllerTest < ActionController::TestCase

  def setup
    @controller = KeysController.new

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

  end

  def teardown
    begin
      @user.force_delete
    rescue
    end
  end

  test "key create show list update and destroy" do
    key_name = "key#{@random}"
    post :create, {"name" => key_name, "type" => "ssh-rsa", "content" => "ABCD1234"}
    assert_response :created
    get :show, {"id" => key_name}
    assert_response :success
    get :index , {}
    assert_response :success
    new_namespace = "xns#{@random}"
    put :update, {"id" => key_name, "type" => "ssh-rsa", "content" => "ABCD1234XYZ"}
    assert_response :success
    delete :destroy , {"id" => key_name}
    assert_response :ok
  end

  test "no key id or bad id" do
    post :create, {"type" => "ssh-rsa", "content" => "ABCD1234"}
    assert_response :unprocessable_entity
    get :show, {}
    assert_response :not_found
    get :show, {"id" => "abcd"}
    assert_response :not_found
    put :update , {"content" => "ABCD1234XYX"}
    assert_response :not_found
    delete :destroy , {}
    assert_response :not_found
  end

  test "duplicate key" do
    key_name = "key#{@random}"
    post :create, {"name" => key_name, "type" => "ssh-rsa", "content" => "ABCD1234"}
    assert_response :created
    #same name
    post :create, {"name" => key_name, "type" => "ssh-rsa", "content" => "ABCD1234XYZ"}
    assert_response :conflict
    #same content
    post :create, {"name" => "abcd", "type" => "ssh-rsa", "content" => "ABCD1234"}
    assert_response :conflict
  end

  test "invalid inputs" do
    key_name = "key#{@random}"
    post :create, {"name" => key_name, "type" => "ssh-rsa"}
    assert_response :unprocessable_entity
    post :create, {"name" => key_name, "content" => "ABCD1234"}
    assert_response :unprocessable_entity
    post :create, {"name" => key_name, "type" => "abcd", "content" => "ABCD1234"}
    assert_response :unprocessable_entity
    #now try update
    post :create, {"name" => key_name, "type" => "ssh-rsa", "content" => "ABCD1234"}
    assert_response :success
    put :update , {"id" => key_name, "type" => "ssh-rsa"}
    assert_response :unprocessable_entity
    put :update , {"id" => key_name, "content" => "ABCD1234"}
    assert_response :unprocessable_entity
    put :update, {"id" => "abcd", "type" => "ssh-rsa", "content" => "ABCD1234XYZ"}
    assert_response :not_found
    post :create, {"name" => key_name + "%", "type" => "ssh-rsa", "content" => "ABCD1234"}
    assert_response :unprocessable_entity
    post :create, {"name" => "." + key_name, "type" => "ssh-rsa", "content" => "ABCD1234"}
    assert_response :unprocessable_entity
    # not ending with json or xml
    post :create, {"name" => key_name + ".json", "type" => "ssh-rsa", "content" => "ABCD1234"}
    assert_response :unprocessable_entity
  end

  test "get keys in all versions" do
    key_name = "key#{@random}"
    post :create, {"name" => key_name, "type" => "ssh-rsa", "content" => "ABCD1234"}
    assert_response :created
    assert json = JSON.parse(response.body)
    assert supported_api_versions = json['supported_api_versions']
    supported_api_versions.each do |version|
      @request.env['HTTP_ACCEPT'] = "application/json; version=#{version}"
      get :show, {"id" => key_name}
      assert_response :ok, "Getting key for version #{version} failed"
    end
  end
end
