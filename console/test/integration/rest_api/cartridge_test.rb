require File.expand_path('../../../test_helper', __FILE__)

class RestApiCartridgeTest < ActiveSupport::TestCase
  include RestApiAuth

  def setup
    with_configured_user
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

    base = cart.scales_from

    cart.scales_from = cart.scales_from + 1
    cart.scales_to = cart.scales_from
    assert cart.save, cart.errors.pretty_inspect

    #cart.reload # Bug in REST API
    app.reload
    cart = app.cartridges.find{ |c| c == cart }

    assert_equal base, cart.scales_from
    assert_equal base, cart.scales_to

  end
end
