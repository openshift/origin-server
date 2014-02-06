ENV["TEST_NAME"] = "functional_ext_app_cartridge_events_test"
require 'test_helper'
require 'openshift-origin-controller'
require 'mocha/setup'

class AppCartridgeEventsTest < ActionDispatch::IntegrationTest

  DOMAIN_COLLECTION_URL = "/broker/rest/domains"
  APP_COLLECTION_URL_FORMAT = "/broker/rest/domains/%s/applications"
  APP_URL_FORMAT = "/broker/rest/domains/%s/applications/%s"
  APP_EVENTS_URL_FORMAT = "/broker/rest/domains/%s/applications/%s/events"
  APP_GEAR_GROUPS_URL_FORMAT = "/broker/rest/domains/%s/applications/%s/gear_groups"
  APP_CARTRIDGES_URL_FORMAT = "/broker/rest/domains/%s/applications/%s/cartridges"
  APP_CARTRIDGE_URL_FORMAT = "/broker/rest/domains/%s/applications/%s/cartridges/%s"
  APP_CARTRIDGE_EVENTS_URL_FORMAT = "/broker/rest/domains/%s/applications/%s/cartridges/%s/events"
  USER_URL = "/broker/rest/user"

  def setup
    @random = rand(1000000000)
    @login = "user#{@random}"
    @password = "password"
    @headers = {}
    @headers["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("#{@login}:#{@password}")
    @headers['REMOTE_USER'] = @login
    @headers["HTTP_ACCEPT"] = "application/json"
    register_user(@login, @password)

    https!
  end

  def teardown
    # delete the domain
    request_via_redirect(:delete, DOMAIN_COLLECTION_URL + "/ns#{@random}", {:force => true}, @headers)
  end

  def test_app_cartridge_event_validation
    ns = "ns#{@random}"

    # create the domain for the user
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:name => ns}, @headers)
    assert_response :created

    # stop application cartridge - without creating application
    request_via_redirect(:post, APP_CARTRIDGE_EVENTS_URL_FORMAT % [ns, "app1", mysql_version], {:event => "stop"}, @headers)
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 101)

    # create application
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app1", :cartridge => php_version}, @headers)
    assert_response :created

    # stop application cartridge - without embedding cartridge
    request_via_redirect(:post, APP_CARTRIDGE_EVENTS_URL_FORMAT % [ns, "app1", mysql_version], {:event => "stop"}, @headers)
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 129)

    # embed mysql-5.1 into the application
    request_via_redirect(:post, APP_CARTRIDGES_URL_FORMAT % [ns, "app1"], {:name => mysql_version}, @headers)
    assert_response :created

    # stop a different application cartridge
    request_via_redirect(:post, APP_CARTRIDGE_EVENTS_URL_FORMAT % [ns, "app1", "mongodb-2.4"], {:event => "stop"}, @headers)
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 129)

    # specify an invalid cartridge event
    request_via_redirect(:post, APP_CARTRIDGE_EVENTS_URL_FORMAT % [ns, "app1", mysql_version], {:event => "invalid"}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 126)
  end

  def test_app_cartridge_events
    ns = "ns#{@random}"

    # create domain
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:name => ns}, @headers)
    assert_response :created

    # create application
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app1", :cartridge => php_version}, @headers)
    assert_response :created

    # embed mysql-5.1 into the application
    request_via_redirect(:post, APP_CARTRIDGES_URL_FORMAT % [ns, "app1"], {:name => mysql_version}, @headers)
    assert_response :created

    # stop mysql
    request_via_redirect(:post, APP_CARTRIDGE_EVENTS_URL_FORMAT % [ns, "app1", mysql_version], {:event => "stop"}, @headers)
    assert_response :ok

    # start mysql
    request_via_redirect(:post, APP_CARTRIDGE_EVENTS_URL_FORMAT % [ns, "app1", mysql_version], {:event => "start"}, @headers)
    assert_response :ok

    # restart mysql
    request_via_redirect(:post, APP_CARTRIDGE_EVENTS_URL_FORMAT % [ns, "app1", mysql_version], {:event => "restart"}, @headers)
    assert_response :ok

    # reload mysql
    request_via_redirect(:post, APP_CARTRIDGE_EVENTS_URL_FORMAT % [ns, "app1", mysql_version], {:event => "reload"}, @headers)
    assert_response :ok

    # query application cartridge after all events
    request_via_redirect(:get, APP_CARTRIDGE_URL_FORMAT % [ns, "app1", mysql_version], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["name"], mysql_version)
    assert_equal(body["data"]["type"], "embedded")
  end

end
