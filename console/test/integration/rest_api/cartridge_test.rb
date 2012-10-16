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

    base = Range.new(cart.supported_scales_from, cart.supported_scales_to == -1 ? User.find(:one, :as => @user).max_gears : [100,cart.supported_scales_to].min).to_a.sample

    name = cart.name

    cart.scales_from = base
    cart.scales_to = base
    assert cart.save, "Unable to set scales_from/to to #{base}: #{cart.errors.full_messages}"

    assert_equal base, cart.scales_from
    assert_equal base, cart.scales_to

    cart.reload rescue omit('Depends on bug 866626 being resolved')

    assert_equal base, cart.scales_from
    assert_equal base, cart.scales_to

  end
end
