ENV["TEST_NAME"] = "functional_jobs_controller_test"
require 'test_helper'
class JobsControllerTest < ActionController::TestCase

  def setup
    @controller = JobsController.new

    @random = rand(1000000000)
    @login = "user#{@random}"
    @password = "password"
    @user = CloudUser.new(login: @login)
    @user.save
    Lock.create_lock(@user.id)
    register_user(@login, @password)

    @request.env['HTTP_AUTHORIZATION'] = "Basic " + Base64.encode64("#{@login}:#{@password}")
    @request.env['REMOTE_USER'] = @login
    @request.env['HTTP_ACCEPT'] = "application/json"
    @namespace = "ns#{@random}"
    @domain = Domain.new(namespace: @namespace, owner:@user)
    @domain.save
    @app_name = "app#{@random}"
    @app = Application.create_app(@app_name, cartridge_instances_for(:php), @domain)
    @app.save
    @app.restart
  end

  def teardown
    begin
      @user.force_delete
    rescue Exception => ex
      puts ex.message
      puts ex.backtrace
    end
  end
  
  test "list and get jobs" do
    get :index , {}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert initial_count = json["data"].length
    assert id = json["data"][0]["id"]
    
    get :show , {"id" => id}
    assert_response :success
    
    delete :destroy, {"id" => id}
    assert_response :success
    
    get :index , {}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert initial_count > json["data"].length

  end

  test "get jobs in all versions" do
    get :index , {}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert supported_api_versions = json['supported_api_versions']
    supported_api_versions.each do |version|
      @request.env['HTTP_ACCEPT'] = "application/json; version=#{version}"
      get :index , {}
      assert_response :ok, "Getting jobs for version #{version} failed"
    end
    @request.env['HTTP_ACCEPT'] = "application/json"
  end
end
