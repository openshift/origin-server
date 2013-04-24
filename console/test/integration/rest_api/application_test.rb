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

  # Needs to be an accessible web cart definition on devenv or public web
  TEST_CART_URL = 'http://test.cart'
  TEST_CART_NAME = 'name'

  def test_create_with_url
    with_configured_user
    setup_domain

    skip "External cartridges are disabled" unless RestApi.external_cartridges_enabled?

    app = Application.new({
      :domain => @domain,
      :name => 'test2',
      :cartridges => [{:url => TEST_CART_URL}],
      :as => @user,
    })

    assert !app.save, "External cartridges are now implemented, uncomment following lines"
    #assert app.save, app.errors.inspect
    #app = @domain.find_application('test2')
    #assert_equal TEST_CART_URL, app.cartridges.first.url
    #assert_equal TEST_CART_NAME, app.cartridges.first.name
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

  def test_create_multiple_cartridges
    with_configured_user
    setup_domain

    assert_create_app({:include => :cartridges, :cartridges => ['ruby-1.9','mysql-5.1']}, "Simple cartridges list") do |app|
      assert_equal ['ruby-1.9', 'mysql-5.1'].sort, app.cartridges.map(&:name).sort
    end
    assert_create_app({:include => :cartridges, :cartridges => [{:name => 'ruby-1.9'},'mysql-5.1']}, "Mixed objects list") do |app|
      assert_equal ['ruby-1.9', 'mysql-5.1'].sort, app.cartridges.map(&:name).sort
    end
  end

  def test_create_app_with_initial_git_url
    with_configured_user
    setup_domain

    assert_create_app({:include => :cartridges, :initial_git_url => 'https://github.com/openshift/wordpress-example', :cartridges => ['php-5.3']}, "Set initial git URL") do |app|
      assert_equal ['php-5.3'], app.cartridges.map(&:name)
      loaded_app = Application.find(app.name, :params => {:domain_id => @domain.id}, :as => @user)
      omit("No initial_git_url returned") unless loaded_app.initial_git_url
      assert_equal "https://github.com/openshift/wordpress-example", loaded_app.initial_git_url
    end
  end

  def assert_create_app(options, message="", &block)
    app = Application.new({:name => 'test', :domain => @domain}.merge(options))
    assert app.save, "#{app.name} could not be saved, #{app.errors.to_hash.inspect}"
    begin
      yield app
    ensure
      puts "Unable to delete app" unless app.destroy
    end
    app
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
    assert [:started, :idle].include? gear.state
    assert gear.id
  end
end
