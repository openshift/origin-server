require 'test_helper'

class LegacyBrokerControllerTest < ActionController::TestCase

  test "cart list" do
    # setup cache
    Rails.cache.clear
    Rails.configuration.action_controller.perform_caching = true
    
    Application.expects(:get_available_cartridges).returns(['php-5.3', 'python-2.6'])

    # should be a cache miss
    resp = post(:cart_list_post, {:json_data => '{"cart_type" : "standalone"}'})
    assert_equal 200, resp.status
    body1 = resp.body

    # should be a cache hit
    resp = post(:cart_list_post, {:json_data => '{"cart_type" : "standalone"}'})
    assert_equal 200, resp.status
    body2 = resp.body

    assert body1 == body2
  end

  test "embedded cart list" do
    # setup cache
    Rails.cache.clear
    Rails.configuration.action_controller.perform_caching = true
    
    Application.expects(:get_available_cartridges).returns(['mysql-5.1', 'phpmyadmin-3.4'])

    # should be a cache miss
    resp = post(:cart_list_post, {:json_data => '{"cart_type" : "embedded"}'})
    assert_equal 200, resp.status
    body1 = resp.body

    # should be a cache hit
    resp = post(:cart_list_post, {:json_data => '{"cart_type" : "embedded"}'})
    assert_equal 200, resp.status
    body2 = resp.body

    assert body1 == body2
  end

end
