ENV["TEST_NAME"] = "system_deployment_test"
require 'test_helper'
require 'openshift-origin-controller'

class DeploymentTest < ActionDispatch::IntegrationTest

  DOMAIN_COLLECTION_URL = "/broker/rest/domains"
  APP_COLLECTION_URL_FORMAT = "/broker/rest/domains/%s/applications"
  APP_URL_FORMAT = "/broker/rest/domains/%s/applications/%s"
  APP_DEPLOYMENT_COLLECTION_URL_FORMAT = "/broker/rest/domains/%s/applications/%s/deployments"
  APP_DEPLOYMENT_URL_FORMAT = "/broker/rest/domains/%s/applications/%s/deployments/%s"

  def setup
    @random = rand(1000000000)
    @login = "user#{@random}"
    @user = CloudUser.new(login: @login)
    @user.save
    Lock.create_lock(@user)
    @headers = {}
    @headers["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("#{@login}:password")
    @headers["HTTP_ACCEPT"] = "application/json"

    https!
  end

  def teardown
    # delete the domain
    request_via_redirect(:delete, DOMAIN_COLLECTION_URL + "/ns#{@random}", {:force => true}, @headers)
  end

  #In the interest of time instead of testing index, show, create, update and destroy individually
  # we have lumped them together
  test "deployment lifecycle" do
    @ns = "ns#{@random}"
    @app = "app#{@random}"

    #create domain
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:name => @ns}, @headers)
    assert_response :created

    # create an application under the user's domain
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [@ns], {:name => @app, :cartridge => "php-5.3"}, @headers)
    assert_response :created

    #update application
    request_via_redirect(:put, APP_URL_FORMAT % [@ns, @app], {:keep_deployments => 3}, @headers)
    assert_response :ok

    # query deployment list
    request_via_redirect(:get, APP_DEPLOYMENT_COLLECTION_URL_FORMAT % [@ns, @app], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"].length, 0)

    # query non-existent deployment
    request_via_redirect(:get, APP_DEPLOYMENT_URL_FORMAT % [@ns, @app, "bogus"], {}, @headers)
    assert_response :not_found

    #try to create deployment with bad inputs
    request_via_redirect(:post, APP_DEPLOYMENT_COLLECTION_URL_FORMAT % [@ns, @app], {:ref => "master", :artifact_url => "myurl"}, @headers)
    assert_response :unprocessable_entity

    #create deployment
    request_via_redirect(:post, APP_DEPLOYMENT_COLLECTION_URL_FORMAT % [@ns, @app], {:ref => "master"}, @headers)
    assert_response :created
    body = JSON.parse(@response.body)
    first_id = body["data"]["id"]
    assert_equal("active" , body["data"]["state"], "deployment state is #{body["data"]["state"]} where it should be active")
    assert_equal(false , body["data"]["hot_deploy"], "hot_deploy is #{body["data"]["hot_deploy"]} where it should be false")
    assert_equal(false , body["data"]["force_clean_build"], "force_clean_build is #{body["data"]["force_clean_build"]} where it should be false")

    #get created deployment
    request_via_redirect(:get, APP_DEPLOYMENT_URL_FORMAT % [@ns, @app, first_id], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["id"], first_id)
    assert_equal("active" , body["data"]["state"], "deployment state is #{body["data"]["state"]} where it should be active")
    assert_equal(false , body["data"]["hot_deploy"], "hot_deploy is #{body["data"]["hot_deploy"]} where it should be false")
    assert_equal(false , body["data"]["force_clean_build"], "force_clean_build is #{body["data"]["force_clean_build"]} where it should be false")

    #create deployment with hot_deploy=true and force_clean_build=true
    request_via_redirect(:post, APP_DEPLOYMENT_COLLECTION_URL_FORMAT % [@ns, @app], {:ref => "master", :hot_deploy => true, :force_clean_build => true}, @headers)
    assert_response :created
    body = JSON.parse(@response.body)
    second_id = body["data"]["id"]
    assert_equal("active" , body["data"]["state"], "deployment state is #{body["data"]["state"]} where it should be active")
    assert_equal(true , body["data"]["hot_deploy"], "hot_deploy is #{body["data"]["hot_deploy"]} where it should be false")
    assert_equal(true , body["data"]["force_clean_build"], "force_clean_build is #{body["data"]["force_clean_build"]} where it should be true")

    #get created deployment
    request_via_redirect(:get, APP_DEPLOYMENT_URL_FORMAT % [@ns, @app, id], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["id"], second_id)
    assert_equal("active" , body["data"]["state"], "deployment state is #{body["data"]["state"]} where it should be active")
    assert_equal(true , body["data"]["hot_deploy"], "hot_deploy is #{body["data"]["hot_deploy"]} where it should be false")
    assert_equal(true , body["data"]["force_clean_build"], "force_clean_build is #{body["data"]["force_clean_build"]} where it should be true")

    #get all deployments
    request_via_redirect(:get, APP_DEPLOYMENT_COLLECTION_URL_FORMAT % [@ns, @app], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(2, body["data"].length)
    deployments = body["data"]
    assert deployments.find{|d| d["state"] == "active"}.length == 1, "There should be one and only one active deployment"

    # rollback application
    APP_EVENTS_URL_FORMAT = "/broker/rest/domains/%s/applications/%s/events"
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [@ns, @app], {:event => "rollback"}, @headers)
    assert_response :ok

    #check to see if rollback happened
    request_via_redirect(:get, APP_DEPLOYMENT_URL_FORMAT % [@ns, @app, id], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["id"], first_id)
    assert_equal("active" , body["data"]["state"], "deployment state is #{body["data"]["state"]} where it should be active")

    request_via_redirect(:get, APP_DEPLOYMENT_URL_FORMAT % [@ns, @app, second_id], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["id"], second_id)
    refute_equal("active" , body["data"]["state"], 'deployment state is #{body["data"]["state"]} where it should NOT be active')

    #get all deployments after rollback
    request_via_redirect(:get, APP_DEPLOYMENT_COLLECTION_URL_FORMAT % [@ns, @app], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(2, body["data"].length)
    deployments = body["data"]
    assert deployments.find{|d| d["state"] == "active"}.length == 1, "There should be one and only one active deployment"

    # try rolling back application again
    APP_EVENTS_URL_FORMAT = "/broker/rest/domains/%s/applications/%s/events"
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [@ns, @app], {:event => "rollback"}, @headers)
    assert_response :unprocessable_entity

    #rollback to the latest deployment
    APP_EVENTS_URL_FORMAT = "/broker/rest/domains/%s/applications/%s/events"
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [@ns, @app], {:event => "rollback", :develpment_id => second_id}, @headers)
    assert_response :ok
    request_via_redirect(:get, APP_DEPLOYMENT_URL_FORMAT % [@ns, @app, second_id], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["id"], second_id)
    assert_equal("active" , body["data"]["state"], 'deployment state is #{body["data"]["state"]} where it should be active')
    request_via_redirect(:get, APP_DEPLOYMENT_COLLECTION_URL_FORMAT % [@ns, @app], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(2, body["data"].length)
    deployments = body["data"]
    assert deployments.find{|d| d["state"] == "active"}.length == 1, "There should be one and only one active deployment"

    #create more deployments and test to see only 3 deployments are kept
    request_via_redirect(:post, APP_DEPLOYMENT_COLLECTION_URL_FORMAT % [@ns, @app], {:ref => "master"}, @headers)
    assert_response :created
    request_via_redirect(:post, APP_DEPLOYMENT_COLLECTION_URL_FORMAT % [@ns, @app], {:ref => "master"}, @headers)
    assert_response :created
    request_via_redirect(:get, APP_DEPLOYMENT_COLLECTION_URL_FORMAT % [@ns, @app], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(3, body["data"].length, "There should only be 3 deployments kept")
    deployments = body["data"]
    assert deployments.find{|d| d["state"] == "active"}.length == 1, "There should be one and only one active deployment"

  end

end
