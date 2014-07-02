require File.expand_path('../../../test_helper', __FILE__)

class RestApiApplicationTest < ActiveSupport::TestCase
  include RestApiAuth

=begin
  def test_partial_creation
    with_configured_user
    setup_domain
    app = Application.new :as => @user, :domain => @domain, :name => 'test2', :cartridge => 'php-5.3'

    done = false
    Thread.new { assert app.save; done = true }
    begin
      begin
        loaded = @domain.find_application('test2')
        assert_equal 'php-5.3', loaded.framework
      rescue RestApi::ResourceNotFound
      end
    end while not done
  end
=end

  def test_create
    with_configured_user
    setup_domain

    app = Application.new :as => @user
    assert !app.save
    assert app.errors[:domain_name].present?, app.errors.inspect

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

  def test_create_with_url
    with_configured_user
    setup_domain

    skip "Downloadable cartridges are disabled" unless RestApi.download_cartridges_enabled?

    app = Application.new({
      :domain => @domain,
      :name => 'test2',
      :cartridges => [{:url => DOWNLOADED_CART_URL}],
      :as => @user,
    })

    assert app.save, app.errors.inspect
    assert_equal DOWNLOADED_CART_URL, app.cartridges.first.url
    assert_nil app.cartridges.first.name # App object is not updated with cart info

    app = @domain.find_application('test2')
    assert_equal DOWNLOADED_CART_URL, app.cartridges.first.url
    assert_equal DOWNLOADED_CART_NAME, app.cartridges.first.name
    assert_equal DOWNLOADED_CART_DISPLAY_NAME, app.cartridges.first.display_name
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

  def test_app_children_not_found_errors
    app = with_app
    opts = app.send(:child_options)

    #m = response_messages(ActiveResource::ResourceInvalid){ app.find_cartridge("_missing!_") }

    m = response_messages(RestApi::ResourceNotFound){ app.find_cartridge("missing-cart-1") }
    assert_messages 1, /cartridge/i, /missing-cart-1/i, m

    m = response_messages(RestApi::ResourceNotFound){ Cartridge.new({:name => 'invalid-cart', :application => app}, true).destroy }
    assert_messages 1, "The requested cartridge was not found.", m

    m = response_messages(RestApi::ResourceNotFound){ app.find_alias("notreal") }
    assert_messages 1, /alias/i, /notreal/i, m

    m = response_messages(RestApi::ResourceNotFound){ Alias.new({:id => 'notfound', :application => app}, true).destroy }
    assert_messages 1, /alias/i, /notfound/i, m

    m = response_messages(RestApi::ResourceNotFound){ app.post(:events, nil, {:event => 'remove-alias', :alias => 'notfound'}.to_json) }
    assert_messages 1, /alias/i, /notfound/i, m

    m = response_messages(RestApi::ResourceNotFound){ GearGroup.find('_bad_id_', opts) }
    assert_messages 1, /gear group/i, /_bad_id_/i, m

    m = response_messages(RestApi::ResourceNotFound){ GearGroup.find('abc123', opts) }
    assert_messages 1, /gear group/i, /abc123/i, m
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

    assert_create_app({:include => :cartridges, :initial_git_url => 'https://github.com/openshift-quickstart/simple_node_express_mongo.git', :cartridges => ['nodejs-0.10', 'mongodb-2.4']}, "Set initial git URL") do |app|
      assert_equal ['mongodb-2.4', 'nodejs-0.10'], app.cartridges.map(&:name)
      loaded_app = Application.find(app.id, :as => @user)
      assert_equal "https://github.com/openshift-quickstart/simple_node_express_mongo.git", loaded_app.initial_git_url
    end
  end

  def test_create_app_with_empty_repo
    with_configured_user
    setup_domain

    assert_create_app({:include => :cartridges, :initial_git_url => 'empty', :cartridges => ['nodejs-0.10']}, "Set initial git URL") do |app|
      assert_equal ['nodejs-0.10'], app.cartridges.map(&:name), "node-js was not an installed cartridge"
      assert app.messages.any?{ |m| m.to_s =~ /An empty Git repository has been created for your application/ }, "None of the app creation messages described the empty repo: #{app.messages.inspect}"
      loaded_app = Application.find(app.id, :as => @user)
      assert loaded_app.initial_git_url.blank?
    end
  end

  def test_create_app_with_initial_git_url_and_fragment
    with_configured_user
    setup_domain

    assert_create_app({:include => :cartridges, :initial_git_url => 'git@github.com:openshift-quickstart/simple_node_express_mongo.git#01c1bedbf79f66366c8eac62b21757891dd6bef1', :cartridges => ['nodejs-0.10', 'mongodb-2.4']}, "Set initial git URL") do |app|
      assert_equal ['mongodb-2.4', 'nodejs-0.10'], app.cartridges.map(&:name)
      loaded_app = Application.find(app.id, :as => @user)
      assert_equal "git@github.com:openshift-quickstart/simple_node_express_mongo.git#01c1bedbf79f66366c8eac62b21757891dd6bef1", loaded_app.initial_git_url
    end
  end

  def test_returns_errors_for_invalid_git_url
    with_configured_user
    setup_domain

    [
      'https://',
      'h',
      'https://localhost!',
      'file:///a/b',
      'test://bar.com',
      'git@bar',
      'git!@bar.com',
      'git@bar.com:',
      'git@bar.com:bar',
    ].each do |url|
      assert_create_app_fails({:include => :cartridges, :initial_git_url => url, :cartridges => ['nodejs-0.10']}, "Set initial git URL") do |app|
        assert_equal ['Invalid initial git URL'], app.errors[:initial_git_url], "Expected error when saving #{url}"
      end
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

  def assert_create_app_fails(options, message="", &block)
    app = Application.new({:name => 'test', :domain => @domain}.merge(options))
    begin
      assert !app.save, "#{app.name} was saved incorrectly"
      assert !app.persisted?
      yield app
    ensure
      puts "Unable to delete app" unless !app.persisted? || app.destroy
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

  def test_applications_get
    app = with_app
    apps = Application.find :all, :as => @user
    assert_equal 1, apps.length
    assert_equal app.name, apps[0].name
  end

  def test_applications_get_by_owner
    with_app
    assert RestApi.info.link('LIST_APPLICATIONS_BY_OWNER')
    apps = Application.find :all, :as => @user
    owned_apps = Application.find :all, :params => {:owner => '@self'}, :as => @user
    assert_equal apps, owned_apps
  end

end
