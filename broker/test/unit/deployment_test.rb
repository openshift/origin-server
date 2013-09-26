ENV["TEST_NAME"] = "unit_deployment_test"
require 'test_helper'

class DeploymentTest < ActiveSupport::TestCase
  def setup
    @random = rand(1000000000)
    @login = "user#{@random}"
    @user = CloudUser.new(login: @login)
    @user.save
    Lock.create_lock(@user)
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
      @domain.applications.each do |app|
        app.delete
      end
      @domain.delete
      @user.delete
    rescue
    end
  end

  test "create and get deployment" do
    d = Deployment.new(deployment_id: 1, ref: "mybranch", activations: [])
    ResultIO.any_instance.stubs(:deployments).returns([{:id => 1, :ref => "mybranch", activations: []}])
    @app.deploy(d)
    assert_equal(1, @app.deployments.length)

    d = Deployment.new(deployment_id: 2, artifact_url: "myurl")
    @app.deploy(d)

    @app.refresh_deployments
  end

  test "create deployment with bad inputs" do

    # conflicting deployment info
    assert Deployment.new(ref: "mybranch", artifact_url: "myurl").invalid?

    # git commit id length
    assert Deployment.new(ref: "0" * 257).invalid?
  end

  test "activate deployment" do

    assert_raise(OpenShift::UserException){@app.activate}

    deployments = []
    for i in 1..5
      @app.deployments.push(Deployment.new(deployment_id: i.to_s, ref: "tag_#{i}"))
    end

    @app.activate

    deployment_id = @app.deployments.last.deployment_id
    @app.activate(deployment_id)
  end

  test "batch update deployments" do
    deployments = []
    for i in 1..5
      deployments.push(Deployment.new(deployment_id: i.to_s, ref: "tag_#{i}"))
    end
    @app.update_deployments(deployments)
    @app.reload
    assert_equal(5, @app.deployments.length)
  end
end
