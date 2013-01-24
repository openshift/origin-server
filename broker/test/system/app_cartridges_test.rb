require 'test_helper'
require 'openshift-origin-controller'
require 'mocha'

class AppCartridgesTest < ActionDispatch::IntegrationTest

  DOMAIN_COLLECTION_URL = "/rest/domains"
  APP_COLLECTION_URL_FORMAT = "/rest/domains/%s/applications"
  APP_URL_FORMAT = "/rest/domains/%s/applications/%s"
  APP_EVENTS_URL_FORMAT = "/rest/domains/%s/applications/%s/events"
  APP_CARTRIDGES_URL_FORMAT = "/rest/domains/%s/applications/%s/cartridges"
  APP_CARTRIDGE_URL_FORMAT = "/rest/domains/%s/applications/%s/cartridges/%s"
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

  def test_app_cartridges_show
    ns = "ns#{@random}"

    # create domain
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:id => ns}, @headers)
    assert_response :created

    # query application cartridge list when application not yet created
    request_via_redirect(:get, APP_CARTRIDGES_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 101)

    # query application cartridge info when application not yet created
    request_via_redirect(:get, APP_CARTRIDGE_URL_FORMAT % [ns, "app1", "mysql-5.1"], {}, @headers)
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 101)

    # create an application under the user's domain
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app1", :cartridge => "php-5.3"}, @headers)
    assert_response :created

    # query application cartridge list after application creation
    request_via_redirect(:get, APP_CARTRIDGES_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"].length, 1)
    assert_equal(body["data"][0]["name"], "php-5.3")
    assert_equal(body["data"][0]["type"], "standalone")

    # query application cartridge info - without embedding cartridge
    request_via_redirect(:get, APP_CARTRIDGE_URL_FORMAT % [ns, "app1", "mysql-5.1"], {}, @headers)
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 129)

    # embed mysql-5.1 into the application
    request_via_redirect(:post, APP_CARTRIDGES_URL_FORMAT % [ns, "app1"], {:name => "mysql-5.1"}, @headers)
    assert_response :created

    # query application cartridge list after embedding mysql-5.1
    request_via_redirect(:get, APP_CARTRIDGES_URL_FORMAT % [ns, "app1"], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"].length, 2)
    
    if body["data"][0]["name"] == "php-5.3"
      php_index = 0
      mysql_index = 1
    elsif body["data"][0]["name"] == "mysql-5.1"
      php_index = 1
      mysql_index = 0
    else
      assert(false, "The cartridge list includes a cartridge other than php-5.3 and mysql-5.1")
    end
    
    assert_equal(body["data"][php_index]["name"], "php-5.3")
    assert_equal(body["data"][php_index]["type"], "standalone")
    assert_equal(body["data"][mysql_index]["name"], "mysql-5.1")
    assert_equal(body["data"][mysql_index]["type"], "embedded")

    # query application cartridge info after embedding mysql-5.1
    request_via_redirect(:get, APP_CARTRIDGE_URL_FORMAT % [ns, "app1", "mysql-5.1"], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["name"], "mysql-5.1")
    assert_equal(body["data"]["type"], "embedded")
  end

  def test_app_cartridge_create
    ns = "ns#{@random}"

    # create domain
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:id => ns}, @headers)
    assert_response :created

    # embed a cartridge - without creating application
    request_via_redirect(:post, APP_CARTRIDGES_URL_FORMAT % [ns, "app1"], {:name => "mysql-5.1"}, @headers)
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 101)

    # create a scalable application
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "appscale", :cartridge => "php-5.3", :scale => true}, @headers)
    assert_response :created

    # create a non-scalable application
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "appnoscale", :cartridge => "php-5.3"}, @headers)
    assert_response :created

    # create an extra non-scalable application to consume all gears
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "appnoscale2", :cartridge => "php-5.3"}, @headers)
    assert_response :created

    # embed an invalid cartridge
    request_via_redirect(:post, APP_CARTRIDGES_URL_FORMAT % [ns, "appnoscale"], {:name => "invalid-cartridge"}, @headers)
    assert_response :bad_request
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 109)

    # embed mysql cartridge into the non-scalable app
    # since the cartridge will reside on the same gear as the app, this should succeed
    request_via_redirect(:post, APP_CARTRIDGES_URL_FORMAT % [ns, "appnoscale"], {:name => "mysql-5.1"}, @headers)
    assert_response :created
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["name"], "mysql-5.1")
    assert_equal(body["data"]["type"], "embedded")

    # embed mysql cartridge AGAIN into the non-scalable app
    request_via_redirect(:post, APP_CARTRIDGES_URL_FORMAT % [ns, "appnoscale"], {:name => "mysql-5.1"}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 136)

    # embed mysql cartridge into the scalable app
    # since the cartridge will reside on a separate gear and with the gear limit of 3 reached, this should fail
    request_via_redirect(:post, APP_CARTRIDGES_URL_FORMAT % [ns, "appscale"], {:name => "mysql-5.1"}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 104)

    ###
    # Note: Currently, co-locating of embedded cartridges within a scalable application is not working as expected
    # Once co-locating works, the two scenarios below can be uncommented and the co-locating functionality can be tested
    ###

#    # embed mysql cartridge into the scalable app - and co-locate it with the php-5.3 cartridge
#    # since this does not create a separate gear, this should succeed
#    request_via_redirect(:post, APP_CARTRIDGES_URL_FORMAT % [ns, "appscale"], {:name => "mysql-5.1", :colocate_with => "php-5.3"}, @headers)
#    assert_response :created
#    body = JSON.parse(@response.body)
#    assert_equal(body["data"]["name"], "mysql-5.1")
#    assert_equal(body["data"]["type"], "embedded")

#    # remove the mysql cartridge from the scalable application
#    request_via_redirect(:delete, APP_CARTRIDGE_URL_FORMAT % [ns, "appscale", "mysql-5.1"], {}, @headers)
#    assert_response :ok
#    body = JSON.parse(@response.body)
#    assert(!body["data"]["embedded"].key?("mysql-5.1"))
#    assert_equal(body["data"]["name"], "appscale")

    # delete the second non-scalable application to free up a gear
    request_via_redirect(:delete, APP_URL_FORMAT % [ns, "appnoscale2"], {}, @headers)
    assert_response :no_content

    # check the user's consumed gears count
    request_via_redirect(:get, USER_URL, {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["consumed_gears"], 2)

    # embed mysql cartridge into the scalable app - without co-locating it
    # this should now pass as we have freed up a gear
    request_via_redirect(:post, APP_CARTRIDGES_URL_FORMAT % [ns, "appscale"], {:name => "mysql-5.1"}, @headers)
    assert_response :created

    # check the user's consumed gears count
    request_via_redirect(:get, USER_URL, {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["consumed_gears"], 3)
  end

  def test_app_cartridge_delete
    ns = "ns#{@random}"
    
    # create the domain for the user
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:id => ns}, @headers)
    assert_response :created

    # delete application cartridge - without creating application
    request_via_redirect(:delete, APP_CARTRIDGE_URL_FORMAT % [ns, "app1", "mysql-5.1"], {}, @headers)
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 101)

    # create application
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [ns], {:name => "app1", :cartridge => "php-5.3"}, @headers)
    assert_response :created

    # delete application cartridge - without embedding cartridge
    request_via_redirect(:delete, APP_CARTRIDGE_URL_FORMAT % [ns, "app1", "mysql-5.1"], {}, @headers)
    assert_response :bad_request
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 129)

    # embed mysql-5.1 into the application
    request_via_redirect(:post, APP_CARTRIDGES_URL_FORMAT % [ns, "app1"], {:name => "mysql-5.1"}, @headers)
    assert_response :created

    # delete a different application cartridge
    request_via_redirect(:delete, APP_CARTRIDGE_URL_FORMAT % [ns, "app1", "mongodb-2.2"], {}, @headers)
    assert_response :bad_request
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 129)

    # delete the embedded mysql cartridge
    request_via_redirect(:delete, APP_CARTRIDGE_URL_FORMAT % [ns, "app1", "mysql-5.1"], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert(!body["data"]["embedded"].key?("mysql-5.1"))
  end
  
end
