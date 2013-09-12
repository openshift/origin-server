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

    d = Deployment.new(deployment_id: 1, ref: "mybranch")
    @app.deploy(d)
    assert(@app.deployments.length == 1)

    d = @app.deployments.find_by(ref: "mybranch")
    assert_equal("mybranch", d.ref)

    d = Deployment.new(deployment_id: 2, ref: "mytag")
    @app.deploy(d)
    assert(@app.deployments.length == 2)

    d = @app.deployments.find_by(ref: "mytag")
    assert_equal("mytag", d.ref)

    d = Deployment.new(deployment_id: 3, ref: "d975cbfd5c398610326c97f3988a52b208036eef")
    @app.deploy(d)
    assert(@app.deployments.length == 3)

    d = @app.deployments.find_by(ref: "d975cbfd5c398610326c97f3988a52b208036eef")
    assert_equal("d975cbfd5c398610326c97f3988a52b208036eef", d.ref)

    d = Deployment.new(deployment_id: 4, artifact_url: "myurl")
    @app.deploy(d)
    assert(@app.deployments.length == 4)

    d = @app.deployments.find_by(artifact_url: "myurl")
    assert_equal("myurl", d.artifact_url)

  end

  test "create deployment with bad inputs" do

    # conflicting deployment info
    assert Deployment.new(ref: "mybranch", artifact_url: "myurl").invalid?

    # git commit id length
    assert Deployment.new(ref: "0" * 257).invalid?
  end

  test "create batch update deployments" do
    deployments = []
    for i in 1..5
      deployments.push(Deployment.new(deployment_id: i, ref: "tag_#{i}"))
    end
    @app.update_deployments(deployments)
    assert_equal(5, @app.deployments.length)
  end
end
