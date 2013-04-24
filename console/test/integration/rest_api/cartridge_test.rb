require File.expand_path('../../../test_helper', __FILE__)

class RestApiCartridgeTest < ActiveSupport::TestCase
  include RestApiAuth

  def setup
    with_configured_user
  end

  # Needs to be an accessible web cart definition on devenv or public web
  TEST_CART_URL = 'http://test.cart'
  TEST_CART_NAME = 'name'

  test 'add a cartridge with a custom URL to an app' do
    skip "External cartridges are disabled" unless RestApi.external_cartridges_enabled?

    cart = Cartridge.new(:url => TEST_CART_URL, :application => with_app)

    assert !cart.save, "External cartridges are now implemented, uncomment following lines"
    #assert cart.save, cart.errors.inspect
    #assert cart = with_app.reload.cartridges.find{ |c| c.url == TEST_CART_URL }
    #assert_equal TEST_CART_URL, cart.url
    #assert_equal TEST_CART_NAME, cart.name
  end

  test 'cartridge scale parameters can be changed' do
    app = with_scalable_app

    carts = app.cartridges.select{ |c| c.scales? }
    assert_equal 1, carts.length

    cart = carts.first
    assert cart.tags.include? :web_framework
    assert cart.scales_from > 0
    assert cart.scales_to != 0
    assert cart.supported_scales_from > 0
    assert_equal(-1, cart.supported_scales_to)

    base = Range.new(cart.supported_scales_from, cart.supported_scales_to == -1 ? User.find(:one, :as => @user).max_gears : [100,cart.supported_scales_to].min).to_a.sample

    name = cart.name

    prefix = cart.prefix_options.dup

    cart.scales_from = base
    cart.scales_to = base
    assert cart.save, "Unable to set scales_from/to to #{base}: #{cart.errors.full_messages}"

    assert_equal base, cart.scales_from
    assert_equal base, cart.scales_to

    assert_equal prefix, cart.prefix_options

    cart.reload 

    assert_equal base, cart.scales_from
    assert_equal base, cart.scales_to
  end
end
