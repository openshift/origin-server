ENV["TEST_NAME"] = "functional_ext_application_test"
require 'test_helper'
require 'openshift-origin-controller'
require 'mocha/setup'

class ApplicationTest < ActionDispatch::IntegrationTest

  DOMAIN_COLLECTION_URL = "/broker/rest/domains"
  APP_COLLECTION_URL_FORMAT = "/broker/rest/domain/%s/applications"
  APP_URL_FORMAT = "/broker/rest/domain/%s/application/%s"
  APP_EVENTS_URL_FORMAT = "/broker/rest/domain/%s/application/%s/events"

  def setup
    @random = rand(1000000000)
    @login = "user#{@random}"
    @password = "password"
    @headers = {}
    @headers["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("#{@login}:#{@password}")
    @headers["HTTP_ACCEPT"] = "application/json"
    @headers['REMOTE_USER'] = @login
    register_user(@login, @password)

    https!
  end

  def teardown
    # delete the domain
    request_via_redirect(:delete, DOMAIN_COLLECTION_URL + "/ns#{@random}", {:force => true}, @headers)
  end

  def test_app_show
    ns = "ns#{@random}"

    # query application list when domain not yet created
    request_via_redirect(:get, APP_COLLECTION_URL_FORMAT % [ns], {}, @headers)
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 127)

    # create domain
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:name => ns}, @headers)
    assert_response :created

    # query application list after domain creation - with no applications
    request_via_redirect(:get, APP_COLLECTION_URL_FORMAT % [ns], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"].length, 0)

    # query application after domain creation - with no application
    request_via_redirect(:get, APP_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 101)

    # create an application under the user's domain
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app1", :cartridge => php_version}, @headers)
    assert_response :created

    # query application list after application creation
    request_via_redirect(:get, APP_COLLECTION_URL_FORMAT % [ns], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"].length, 1)
    assert_equal(body["data"][0]["name"], "app1")
    assert_equal(body["data"][0]["framework"], php_version)
    assert_equal(body["data"][0]["domain_id"], ns)

    # query application after creation
    request_via_redirect(:get, APP_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["name"], "app1")
    assert_equal(body["data"]["framework"], php_version)
    assert_equal(body["data"]["domain_id"], ns)
  end

  def test_app_create_validation
    ns = "ns#{@random}"

    # create an application - without creating domain
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app1", :cartridge => php_version}, @headers)
    assert_response :created

    # create an application - without specifying app name
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 105)

    # create an application - without specifying app framework
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app1"}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 109)

    # create an application - and specify invalid cartridge
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app1", :cartridge => "invalid-cartridge"}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 109)

    # create an application - and specify invalid node profile
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app1", :cartridge => php_version, :gear_profile => "invalidprofile"}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 134)

    # create an application - and specify invalid name
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app_name", :cartridge => php_version}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 105)

    # create an application - and specify empty name
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "", :cartridge => php_version}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 105)

    # create an application - and specify long name
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app123456789012345678901234567890", :cartridge => php_version}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 105)

  end

  def test_app_limit_and_duplicate
    ns = "ns#{@random}"

    # create domain
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:name => ns}, @headers)
    assert_response :created
    assert_equal 0, Domain.find_by(namespace: ns).owner.consumed_gears

    #set gear limit
    system "oo-broker --non-interactive oo-admin-ctl-user -l #{@login} --setmaxgears 3"

    # create application #1
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app1", :cartridge => php_version}, @headers)
    assert_response :created
    assert_equal 1, Domain.find_by(namespace: ns).owner.consumed_gears

    # try create another application with the same name
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app1", :cartridge => php_version}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 100)
    assert_equal 1, Domain.find_by(namespace: ns).owner.consumed_gears

    # create application #2
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app2", :cartridge => php_version}, @headers)
    assert_response :created

    # create an application #3
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app3", :cartridge => php_version}, @headers)
    assert_response :created

    # create application #4
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app4", :cartridge => php_version}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 104)

    # query application list
    request_via_redirect(:get, APP_COLLECTION_URL_FORMAT % [ns], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"].length, 3)
  end

  def test_app_delete
    ns = "ns#{@random}"

    # delete the application - without creating the domain
    request_via_redirect(:delete, APP_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 127)

    # create the domain for the user
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:name => ns}, @headers)
    assert_response :created

    # delete the application - without creating the application
    request_via_redirect(:delete, APP_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 101)

    # create application
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app1", :cartridge => php_version}, @headers)
    assert_response :created

    # delete the application
    request_via_redirect(:delete, APP_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :ok

    # query application after deletion
    request_via_redirect(:get, APP_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 101)
  end

  def test_app_update
    ns = "ns#{@random}"

    # create domain
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:name => ns}, @headers)
    assert_response :created

    # create an application under the domain
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app1", :cartridge => php_version}, @headers)
    assert_response :created

    #update application making sure only what is updated is changed
    request_via_redirect(:put, APP_URL_FORMAT % [ns, "app1"], {:name => "app1", :deployment_branch => "stage"}, @headers)
    assert_response :ok
    request_via_redirect(:get, APP_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["auto_deploy"], true)
    assert_equal(body["data"]["deployment_branch"], "stage")
    assert_equal(body["data"]["keep_deployments"], 1)
    assert_equal(body["data"]["deployment_type"], "git")

    #update application making sure only what is updated is changed
    request_via_redirect(:put, APP_URL_FORMAT % [ns, "app1"], {:name => "app1", :keep_deployments => 3}, @headers)
    assert_response :ok
    request_via_redirect(:get, APP_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["auto_deploy"], true)
    assert_equal(body["data"]["deployment_branch"], "stage")
    assert_equal(body["data"]["keep_deployments"], 3)
    assert_equal(body["data"]["deployment_type"], "git")

    #update application making sure only what is updated is changed
    request_via_redirect(:put, APP_URL_FORMAT % [ns, "app1"], {:name => "app1", :deployment_type => "binary"}, @headers)
    assert_response :ok
    request_via_redirect(:get, APP_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["auto_deploy"], true)
    assert_equal(body["data"]["deployment_branch"], "stage")
    assert_equal(body["data"]["keep_deployments"], 3)
    assert_equal(body["data"]["deployment_type"], "binary")

    #update application making sure only what is updated is changed
    request_via_redirect(:put, APP_URL_FORMAT % [ns, "app1"], {:name => "app1", :auto_deploy => false}, @headers)
    assert_response :ok
    request_via_redirect(:get, APP_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["auto_deploy"], false)
    assert_equal(body["data"]["deployment_branch"], "stage")
    assert_equal(body["data"]["keep_deployments"], 3)
    assert_equal(body["data"]["deployment_type"], "binary")

    #update application to default values
    request_via_redirect(:put, APP_URL_FORMAT % [ns, "app1"], {:name => "app1", :auto_deploy => true, :deployment_branch => "master", :keep_deployments => 1, :deployment_type => "git"}, @headers)
    assert_response :ok

    request_via_redirect(:get, APP_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["auto_deploy"], true)
    assert_equal(body["data"]["deployment_branch"], "master")
    assert_equal(body["data"]["keep_deployments"], 1)
    assert_equal(body["data"]["deployment_type"], "git")

    #test update application with bad input
    request_via_redirect(:put, APP_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :unprocessable_entity

    request_via_redirect(:put, APP_URL_FORMAT % [ns, "app1"], {:name => "app1", :auto_deploy => "bogus", :deployment_branch => "stage", :keep_deployments => 3, :deployment_type => "binary"}, @headers)
    assert_response :unprocessable_entity

    request_via_redirect(:put, APP_URL_FORMAT % [ns, "app1"], {:name => "app1", :auto_deploy => false, :deployment_branch => "0" * 999, :keep_deployments => 3, :deployment_type => "binary"}, @headers)
    assert_response :unprocessable_entity

    request_via_redirect(:put, APP_URL_FORMAT % [ns, "app1"], {:name => "app1", :auto_deploy => false, :deployment_branch => "stage", :keep_deployments => 0, :deployment_type => "binary"}, @headers)
    assert_response :unprocessable_entity

    request_via_redirect(:put, APP_URL_FORMAT % [ns, "app1"], {:name => "app1", :auto_deploy => false, :deployment_branch => "stage", :keep_deployments => 3, :deployment_type => "bogus"}, @headers)
    assert_response :unprocessable_entity
  end

end
