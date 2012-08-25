require File.expand_path('../../../test_helper', __FILE__)

class RestApiApplicationTest < ActiveSupport::TestCase
  include RestApiAuth

  def setup
    with_configured_user
  end
  def teardown
    cleanup_domain
  end

  def test_create
    setup_domain

    app = Application.new :as => @user
    assert_raise(ActiveResource::ResourceNotFound) { app.save }

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
  end

  def test_retrieve_gears
    setup_domain
    app = Application.create :name => 'test', :domain => @domain, :cartridge => 'php-5.3', :as => @user

    assert gears = app.gears
    assert_equal 1, gears.length
  end

  def test_retrieve_gear_groups
    app = Application.create :name => 'test', :domain => setup_domain, :cartridge => 'php-5.3', :as => @user

    cart = Cartridge.new :name => 'php-5.3'

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
