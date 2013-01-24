require 'rubygems'
require 'test_helper'
require 'openshift-origin-controller'
require 'mocha'

class AppEventsTest < ActionDispatch::IntegrationTest

  DOMAIN_COLLECTION_URL = "/rest/domains"
  APP_COLLECTION_URL_FORMAT = "/rest/domains/%s/applications"
  APP_URL_FORMAT = "/rest/domains/%s/applications/%s"
  APP_EVENTS_URL_FORMAT = "/rest/domains/%s/applications/%s/events"
  APP_GEAR_GROUPS_URL_FORMAT = "/rest/domains/%s/applications/%s/gear_groups"

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

  def test_app_event_validation
    ns = "ns#{@random}"

    # create domain
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:id => ns}, @headers)
    assert_response :created

    # stop application - without creating an application
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [ns, "app1"], {:event => "stop"}, @headers)
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 101)

    # create application
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app1", :cartridge => "php-5.3"}, @headers)
    assert_response :created

    # do not specify event
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 126)

    # specify empty event
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [ns, "app1"], {:event => ""}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 126)
  
    # specify invalid event
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [ns, "app1"], {:event => "invalidevent"}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 126)
  end
  
  def test_app_start_stop_restart
    ns = "ns#{@random}"

    # create domain
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:id => ns}, @headers)
    assert_response :created

    # create application
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app1", :cartridge => "php-5.3"}, @headers)
    assert_response :created

    # check the application state
    request_via_redirect(:get, APP_GEAR_GROUPS_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"][0]["gears"][0]["state"], "started")
    
    # stop application
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [ns, "app1"], {:event => "stop"}, @headers)
    assert_response :ok

    # check the application state
    request_via_redirect(:get, APP_GEAR_GROUPS_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"][0]["gears"][0]["state"], "stopped")
    
    # start application
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [ns, "app1"], {:event => "start"}, @headers)
    assert_response :ok

    # check the application state
    request_via_redirect(:get, APP_GEAR_GROUPS_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"][0]["gears"][0]["state"], "started")

    # restart application
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [ns, "app1"], {:event => "restart"}, @headers)
    assert_response :ok

    # check the application state
    request_via_redirect(:get, APP_GEAR_GROUPS_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"][0]["gears"][0]["state"], "started")

    # force-stop application
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [ns, "app1"], {:event => "force-stop"}, @headers)
    assert_response :ok

    # check the application state
    request_via_redirect(:get, APP_GEAR_GROUPS_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"][0]["gears"][0]["state"], "stopped")

    # query application after all events
    request_via_redirect(:get, APP_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["name"], "app1")
    assert_equal(body["data"]["framework"], "php-5.3")
    assert_equal(body["data"]["domain_id"], ns)
  end
  
  def test_app_port_events
    ns = "ns#{@random}"

    # create domain
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:id => ns}, @headers)
    assert_response :created

    # create application
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app1", :cartridge => "php-5.3"}, @headers)
    assert_response :created

    # expose-port application
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [ns, "app1"], {:event => "expose-port"}, @headers)
    assert_response :gone

    # conceal-port application
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [ns, "app1"], {:event => "conceal-port"}, @headers)
    assert_response :gone

    # show-port application
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [ns, "app1"], {:event => "show-port"}, @headers)
    assert_response :gone

    # query application after all events
    request_via_redirect(:get, APP_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["name"], "app1")
    assert_equal(body["data"]["framework"], "php-5.3")
    assert_equal(body["data"]["domain_id"], ns)
  end

  def test_app_alias_events
    ns = "ns#{@random}"

    # create domain
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:id => ns}, @headers)
    assert_response :created

    # create application
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app1", :cartridge => "php-5.3"}, @headers)
    assert_response :created

    # add-alias application - do not specify alias
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [ns, "app1"], {:event => "add-alias"}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 126)

    # add-alias application - specify empty alias
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [ns, "app1"], {:event => "add-alias", :alias => ""}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 105)

    # add-alias application - specify invalid alias
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [ns, "app1"], {:event => "add-alias", :alias => "invalid@alias"}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 105)

    # add-alias application
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [ns, "app1"], {:event => "add-alias", :alias => "alias#{@random}"}, @headers)
    assert_response :ok

    # query application after adding alias
    request_via_redirect(:get, APP_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["name"], "app1")
    assert_equal(body["data"]["framework"], "php-5.3")
    assert_equal(body["data"]["aliases"].length, 1)
    assert_equal(body["data"]["aliases"][0], "alias#{@random}")

    # add-alias application - specify same alias again
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [ns, "app1"], {:event => "add-alias", :alias => "alias#{@random}"}, @headers)
    assert_response :unprocessable_entity

    # remove-alias application
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [ns, "app1"], {:event => "remove-alias", :alias => "alias#{@random}"}, @headers)
    assert_response :ok

    # query application after removing alias
    request_via_redirect(:get, APP_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["name"], "app1")
    assert_equal(body["data"]["framework"], "php-5.3")
    assert_equal(body["data"]["domain_id"], ns)
    assert_equal(body["data"]["aliases"].length, 0)
  end

  def test_app_scaling_events
    ns = "ns#{@random}"

    # create domain
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:id => ns}, @headers)
    assert_response :created

    # create non-scalable application
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "appnoscale", :cartridge => "php-5.3"}, @headers)
    assert_response :created

    # scale-up application
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [ns, "appnoscale"], {:event => "scale-up"}, @headers)
    assert_response :unprocessable_entity

    # create scalable application
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app1", :cartridge => "php-5.3", :scale => true}, @headers)
    assert_response :created

    # scale-up application
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [ns, "app1"], {:event => "scale-up"}, @headers)
    assert_response :ok

    # scale-up application - this should fail since the user has already consumed all 3 gears 
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [ns, "app1"], {:event => "scale-up"}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 104)

    # scale-down application
    request_via_redirect(:post, APP_EVENTS_URL_FORMAT % [ns, "app1"], {:event => "scale-down"}, @headers)
    assert_response :ok

    # query application after scaledown
    request_via_redirect(:get, APP_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["gear_count"], 1)
    assert_equal(body["data"]["name"], "app1")
    assert_equal(body["data"]["domain_id"], ns)
  end

end
