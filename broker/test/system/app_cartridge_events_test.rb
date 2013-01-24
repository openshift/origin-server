require 'test_helper'
require 'openshift-origin-controller'
require 'mocha'

class AppCartridgeEventsTest < ActionDispatch::IntegrationTest

  DOMAIN_COLLECTION_URL = "/rest/domains"
  APP_COLLECTION_URL_FORMAT = "/rest/domains/%s/applications"
  APP_URL_FORMAT = "/rest/domains/%s/applications/%s"
  APP_EVENTS_URL_FORMAT = "/rest/domains/%s/applications/%s/events"
  APP_GEAR_GROUPS_URL_FORMAT = "/rest/domains/%s/applications/%s/gear_groups"
  APP_CARTRIDGES_URL_FORMAT = "/rest/domains/%s/applications/%s/cartridges"
  APP_CARTRIDGE_URL_FORMAT = "/rest/domains/%s/applications/%s/cartridges/%s"
  APP_CARTRIDGE_EVENTS_URL_FORMAT = "/rest/domains/%s/applications/%s/cartridges/%s/events"
  USER_URL = "/rest/user"

  def setup
    @random = rand(1000000)
    @login = "user#{@random}"
    @headers = {}
    @headers["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("#{@login}:password")
    @headers["HTTP_ACCEPT"] = "application/json"
    
    https!
  end
  
  def teardown
    # delete the domain
    request_via_redirect(:delete, DOMAIN_COLLECTION_URL + "/ns#{@random}", {:force => true}, @headers)
  end

  def test_app_cartridge_event_validation
    ns = "ns#{@random}"
    
    # create the domain for the user
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:id => ns}, @headers)
    assert_response :created

    # stop application cartridge - without creating application
    request_via_redirect(:post, APP_CARTRIDGE_EVENTS_URL_FORMAT % [ns, "app1", "mysql-5.1"], {:event => "stop"}, @headers)
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 101)

    # create application
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app1", :cartridge => "php-5.3"}, @headers)
    assert_response :created

    # stop application cartridge - without embedding cartridge
    request_via_redirect(:post, APP_CARTRIDGE_EVENTS_URL_FORMAT % [ns, "app1", "mysql-5.1"], {:event => "stop"}, @headers)
    assert_response :bad_request
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 129)

    # embed mysql-5.1 into the application
    request_via_redirect(:post, APP_CARTRIDGES_URL_FORMAT % [ns, "app1"], {:name => "mysql-5.1"}, @headers)
    assert_response :created

    # stop a different application cartridge
    request_via_redirect(:post, APP_CARTRIDGE_EVENTS_URL_FORMAT % [ns, "app1", "mongodb-2.2"], {:event => "stop"}, @headers)
    assert_response :bad_request
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 129)

    # specify an invalid cartridge event
    request_via_redirect(:post, APP_CARTRIDGE_EVENTS_URL_FORMAT % [ns, "app1", "mysql-5.1"], {:event => "invalid"}, @headers)
    assert_response :bad_request
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 126)
  end
  
  def test_app_cartridge_events
    ns = "ns#{@random}"

    # create domain
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:id => ns}, @headers)
    assert_response :created

    # create application
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app1", :cartridge => "php-5.3"}, @headers)
    assert_response :created

    # embed mysql-5.1 into the application
    request_via_redirect(:post, APP_CARTRIDGES_URL_FORMAT % [ns, "app1"], {:name => "mysql-5.1"}, @headers)
    assert_response :created

    # stop mysql
    request_via_redirect(:post, APP_CARTRIDGE_EVENTS_URL_FORMAT % [ns, "app1", "mysql-5.1"], {:event => "stop"}, @headers)
    assert_response :ok

    # start mysql
    request_via_redirect(:post, APP_CARTRIDGE_EVENTS_URL_FORMAT % [ns, "app1", "mysql-5.1"], {:event => "start"}, @headers)
    assert_response :ok

    # restart mysql
    request_via_redirect(:post, APP_CARTRIDGE_EVENTS_URL_FORMAT % [ns, "app1", "mysql-5.1"], {:event => "restart"}, @headers)
    assert_response :ok

    # reload mysql
    request_via_redirect(:post, APP_CARTRIDGE_EVENTS_URL_FORMAT % [ns, "app1", "mysql-5.1"], {:event => "reload"}, @headers)
    assert_response :ok

    # query application cartridge after all events
    request_via_redirect(:get, APP_CARTRIDGE_URL_FORMAT % [ns, "app1", "mysql-5.1"], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["name"], "mysql-5.1")
    assert_equal(body["data"]["type"], "embedded")
  end

end
