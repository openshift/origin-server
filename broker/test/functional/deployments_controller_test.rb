ENV["TEST_NAME"] = "functional_deployment_controller_test"
require 'test_helper'
class DeploymentsControllerTest < ActionController::TestCase

  def setup
    @controller = DeploymentsController.new

    @random = rand(1000000000)
    @login = "user#{@random}"
    @password = 'password'
    @user = CloudUser.new(login: @login)
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
    @app = Application.create_app(@app_name, [PHP_VERSION], @domain)
    @app.save
  end

  def teardown
    begin
      @user.force_delete
    rescue
    end
  end

  test "deployment create show list" do
    Application.any_instance.stubs(:deployments).returns([Deployment.new(ref: "mybranch", deployment_id: "1")])
    post :create, {"ref" => "mybranch", "application_id" => @app.uuid}
    assert_response :created
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']

    get :show, {"id" => id, "application_id" => @app.uuid}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal id, json['data']['id'] 

    get :index , {"application_id" => @app.uuid}
    assert_response :success
  end

  test "update deployments" do
    deployments = []
    for i in 1..5
      deployments.push({:id => i.to_s, :ref => "tag_#{i}"})
    end
    post :create, {"deployments" => deployments, "application_id" => @app.uuid}
    assert_response :success
    get :index , {"application_id" => @app.uuid}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert data = json['data']
    assert_equal(5, data.length)
  end

  test "no or non-existent deployment" do
    get :show, {"application_id" => @app.id}
    assert_response :not_found
    get :show, {"application_id" => @app.id, "id" => "bogus"}
    assert_response :not_found
  end
end
