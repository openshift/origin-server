ENV["TEST_NAME"] = "functional_cartridges_controller_test"
require 'test_helper'
require 'openshift-origin-controller'
require 'mocha'

class CartridgesControllerTest < ActionDispatch::IntegrationTest

  def setup
    @headers = {}
    @headers["HTTP_ACCEPT"] = "application/json"

    https!
  end

  test "cart list" do
    # setup cache
    Rails.cache.clear
    Rails.configuration.action_controller.perform_caching = true
    
    # should be a cache miss
    request_via_redirect(:get, "/rest/cartridges/standalone", {}, @headers)
    assert_response :ok
    body1 = JSON.parse(@response.body)
    cart_count1 = body1["data"].length
    assert cart_count1 > 0

    # should be a cache hit
    request_via_redirect(:get, "/rest/cartridges/standalone", {}, @headers)
    assert_response :ok
    body2 = JSON.parse(@response.body)
    cart_count2 = body2["data"].length
    assert cart_count2 > 0

    assert body1 == body2
  end

  test "embedded cart list" do
    # setup cache
    Rails.cache.clear
    Rails.configuration.action_controller.perform_caching = true

    # should be a cache miss
    request_via_redirect(:get, "/rest/cartridges/embedded", {}, @headers)
    assert_response :ok
    body1 = JSON.parse(@response.body)
    cart_count1 = body1["data"].length
    assert cart_count1 > 0

    # should be a cache hit
    request_via_redirect(:get, "/rest/cartridges/embedded", {}, @headers)
    assert_response :ok
    body2 = JSON.parse(@response.body)
    cart_count2 = body2["data"].length
    assert cart_count2 > 0

    assert body1 == body2
  end
  
  test "find cartridge" do

    request_via_redirect(:get, "/rest/cartridges/redhat-#{PHP_VERSION}", {}, @headers)
    assert_response :ok
    body1 = JSON.parse(@response.body)
    cart_count1 = body1["data"].length
    assert cart_count1 > 0
    
    request_via_redirect(:get, "/rest/cartridges/#{PHP_VERSION}", {}, @headers)
    assert_response :ok
    body1 = JSON.parse(@response.body)
    cart_count1 = body1["data"].length
    assert cart_count1 > 0
    
    request_via_redirect(:get, "/rest/cartridges/php", {}, @headers)
    assert_response :ok
    body1 = JSON.parse(@response.body)
    cart_count1 = body1["data"].length
    assert cart_count1 > 0
    
  end

end
