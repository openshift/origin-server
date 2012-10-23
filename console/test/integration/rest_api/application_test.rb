require File.expand_path('../../../test_helper', __FILE__)

class RestApiApplicationTest < ActiveSupport::TestCase
  include RestApiAuth

  def test_create
    with_configured_user
    setup_domain

    app = Application.new :as => @user
    assert_raise(ActiveResource::MissingPrefixParam) { app.save }

    app.domain = @domain

    assert !app.save
    assert app.errors[:name].present?, app.errors.inspect

    app.name = 'test'

    assert !app.save
    assert app.errors[:cartridge].present?, app.errors.inspect

    app.cartridge = 'php-5.3'

    assert app.save, app.errors.inspect
    saved_app = @domain.find_application('test')
    app.schema.each_key do |key|
      value = app.send(key)
      assert_equal app.send(key), saved_app.send(key) unless value.nil?
    end

    assert_nil app.building_app
    assert_nil app.building_with

    prefix_options = app.prefix_options
    app.reload
    assert_equal prefix_options, app.prefix_options
  end

  def test_retrieve_cartridges
    #setup_domain
    #app = Application.create :name => 'test', :domain => @domain, :cartridge => 'php-5.3', :as => @user
    app = with_app

    assert cartridges = app.cartridges
    assert_equal 1, cartridges.length
    assert cart = cartridges.first
    assert_equal app.framework, cart.name
    assert cart.description
    assert cart.tags.present?

    # scaling parameters
    assert_nil cart.scales_with
    assert_equal 1, cart.supported_scales_from
    assert_equal 1, cart.supported_scales_to
    assert_equal 1, cart.current_scale
    assert_equal 1, cart.scales_from
    assert_equal 1, cart.scales_to
    assert !cart.scales?
  end

  def test_retrieve_gear_groups
    app = with_app

    cart = Cartridge.new :name => app.framework

    assert groups = app.gear_groups

    assert_equal 1, groups.length
    group = groups[0]
    assert group.is_a? GearGroup
    assert group.name
    assert_equal [cart], group.cartridges
    assert_equal 1, group.gears.length
    gear = group.gears[0]
    assert gear.is_a? Gear
    assert_equal :started, gear.state
    assert gear.id
  end
end
