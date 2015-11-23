ENV["TEST_NAME"] = "functional_deployment_controller_test"
require 'test_helper'
class DeploymentsControllerTest < ActionController::TestCase

  def setup
    @controller = DeploymentsController.new

    @random = rand(1000000000)
    @login = "user#{@random}"
    @password = 'password'
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
    @app = Application.create_app(@app_name, cartridge_instances_for(:php), @domain)
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
    @app.config["deployment_type"] = "git"
    @app.save

    ResultIO.any_instance.stubs(:deployments).returns([{:id => 1, :ref => "mybranch", :sha1 => "1234", :created_at => Time.now, :activations => [Time.now, Time.now]}])
    post :create, {"ref" => "mybranch", "application_id" => @app._id}
    assert_response :created
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']

    get :show, {"id" => id, "application_id" => @app._id}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal id, json['data']['id']

    @request.env['HTTP_ACCEPT'] = 'application/xml'
    get :show, {"id" => id, "application_id" => @app._id}
    assert_response :success
    @request.env['HTTP_ACCEPT'] = 'application/json'

    get :index , {"application_id" => @app._id}
    assert_response :success
  end

  test "update deployments" do
    CloudUser.any_instance.stubs(:scopes).returns(Scope::Scopes.new << Scope::Application.new(:id => @app._id.to_s, :app_scope => :report_deployments))
    deployments = []
    for i in 1..5
      deployments.push({:id => i.to_s, :ref => "tag_#{i}", created_at: Time.now, activations: [Time.now.to_f, Time.now.to_f]})
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

  test "validate supported binary artifact formats" do
    @domain.members.find(@user).role = :edit
    @domain.save; @domain.run_jobs
    @app.config["deployment_type"] = "binary"
    @app.save

    supported_artifact_urls = ["http://localhost/test1.tgz", "http://localhost/test2.tar.gz", "https://localhost/test3.tgz", "https://localhost/test4.tar.gz", "ftp://localhost/test5.tgz", "ftp://localhost/test6.tar.gz", "http://localhost/{558F2532-1116}/test.tgz", "https://localhost/url with space/test7.tgz"]
    unsupported_artifact_urls = ["badurl1/test7.tgz", "notreal://localhost/test8.tgz", "http://localhost/test9.txt", "https://localhost/test10.txt", "http://localhost/test11", "test12", "-1", '!@#!@#@!#!', "not a url", '$%*!&#@!&#!)*#@!DAZSXCAS#R@#_@(_$*%)@*)#@*$_#@i[sadfsa]ew34122]\safdsa|xczxcz', '&^#$%!CSCA#@$#@FDS', "http://localhost/test13.tar", "http://somehost/test14.gz"]

    supported_artifact_urls.each { |test_url|
      ResultIO.any_instance.stubs(:deployments).returns([{:id => 1, :ref => "mybranch", :sha1 => "1234", :created_at => Time.now, :activations => [Time.now, Time.now]}])
      post :create, { "application_id" => @app._id, "artifact_url" => test_url }
      assert_response :success
      json          = JSON.parse(response.body)
      assert_equal "1", json["data"]["id"]
    }

    unsupported_artifact_urls.each { |test_url|
      ResultIO.any_instance.stubs(:deployments).returns([{:id => 1, :ref => "mybranch", :sha1 => "1234", :created_at => Time.now, :activations => [Time.now, Time.now]}])
      post :create, { "application_id" => @app._id, "artifact_url" => test_url }
      json          = JSON.parse(response.body)
      message       = json["messages"][0]
      msg_exit_code = -1
      msg_test      = "Invalid Binary Artifact URL(#{URI::encode(test_url)})"
      assert_equal msg_test, message["text"]
      assert_equal msg_exit_code, message["exit_code"]
    }
  end

  test "validate ref" do
    @app.config["deployment_type"] = "git"
    @app.save

    # See git-check-ref-format man page for rules
    invalid_values = ["a"*257, "abc.lock", "abc/.xyz", "abc..xyz", "/abc", "abc/", "abc//xyz", "abc.", "abc@{xyz}"]
    invalid_chars = ["^", "~", ":", "?", "*", "\\", " ", "[", ";"]
    invalid_chars.each do |invalid_char|
      invalid_values.push("abc#{invalid_char}xyz")
    end
    invalid_values.each do |invalid_value|
      post :create, { "application_id" => @app._id, "ref" => invalid_value }
      assert_response :unprocessable_entity, "Expected value ref:#{invalid_value} to be rejected"
    end
  end

  test "check for both binary and git deployment input" do
    # Check for cases where we have both a ref and an artifact_url
    test_url = "http://localhost/test.tgz"
    test_ref = "branchname"
    post :create, { "application_id" => @app._id, "artifact_url" => test_url, "ref" => test_ref }
    assert_response :unprocessable_entity, "Cannot specify a git deployment and a binary artifact deployment"
  end

  test "check for no binary or git deployment input" do
    # Check for cases where we have have neither a ref nor an artifact_url
    post :create, { "application_id" => @app._id, "artifact_url" => nil, "ref" => nil }
    assert_response :unprocessable_entity, "Must specify a git deployment or a binary artifact deployment"
  end

end
