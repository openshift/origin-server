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

  test "attempt to create and update deployments without permission" do
    scopes = Scope::Scopes.new
    CloudUser.any_instance.stubs(:scopes).returns(scopes << Scope::Read.new)
    post :create, {"ref" => "mybranch", "application_id" => @app._id}
    assert_response :forbidden

    @domain.members.find(@user).role = :edit
    @domain.save; @domain.run_jobs

    post :create, {"deployments" => [], "application_id" => @app._id}
    assert_response :forbidden
  end

  test "deployment create show list" do
    @domain.members.find(@user).role = :edit
    @domain.save; @domain.run_jobs

    ResultIO.any_instance.stubs(:deployments).returns([{:id => 1, :ref => "mybranch", :sha1 => "1234", :created_at => 1234.0, :activations => [1.0, 2.0]}])
    post :create, {"ref" => "mybranch", "application_id" => @app._id}
    assert_response :created
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']

    get :show, {"id" => id, "application_id" => @app._id}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal id, json['data']['id']

    get :index , {"application_id" => @app._id}
    assert_response :success
  end

  test "update deployments" do
    CloudUser.any_instance.stubs(:scopes).returns(Scope::Scopes.new << Scope::Application.new(:id => @app._id.to_s, :app_scope => :report_deployments))
    deployments = []
    for i in 1..5
      deployments.push({:id => i.to_s, :ref => "tag_#{i}"})
    end
    post :create, {"deployments" => deployments, "application_id" => @app._id}
    assert_response :success
    get :index , {"application_id" => @app._id}
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
