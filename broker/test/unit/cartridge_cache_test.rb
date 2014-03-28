ENV["TEST_NAME"] = "unit_cartridge_cache_test"
require_relative '../test_helper'

class CartridgeCacheTest < ActiveSupport::TestCase
  setup{ Rails.cache.clear }
  teardown{ Rails.cache.clear }

  def stub_cartridges
    carts = []
    #redhat and another cartridge_vendor providing the same cartridge
    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "redhat"
    cart.name = "php"
    cart.provides = ["php"]
    cart.version = "5.3"

    carts << cart
    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "other"
    cart.name = "php"
    cart.provides = ["php"]
    cart.version = "5.3"
    carts << cart

    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "other"
    cart.name = "php"
    cart.provides = ["php"]
    cart.version = "5.4"
    carts << cart

    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "other"
    cart.name = "php"
    cart.provides = ["php", "php-5.5"]
    cart.version = "5.5"
    carts << cart

    # 2 different cartridge_vendors providing the same cartridge
    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "other"
    cart.name = "python"
    cart.provides = ["python"]
    cart.version = "3.3"
    carts << cart

    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "another"
    cart.name = "python"
    cart.provides = ["python"]
    cart.version = "3.3"
    carts << cart

    #redhat has more than one version of cartridge
    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "redhat"
    cart.name = "ruby"
    cart.provides = ["ruby"]
    cart.version = "1.8"

    carts << cart
    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "redhat"
    cart.name = "ruby"
    cart.provides = ["ruby"]
    cart.version = "1.9"
    carts << cart

    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "other"
    cart.name = "ruby"
    cart.provides = ["ruby"]
    cart.version = "1.10"
    carts << cart

    CartridgeCache.stubs(:get_all_cartridges).returns(carts)
  end

  test "manifest syntax error raises InvalidManifestError" do
    assert_raises(OpenShift::InvalidManifest) do
      OpenShift::Runtime::Manifest.manifests_from_yaml("--- `")
    end
  end

  test "cartridge is properly loaded from overrides" do
    manifest = %q{#
        Name: crtest
        Display-Name: crtest Unit Test
        Cartridge-Short-Name: CRTEST
        Version: '0.3'
        Versions: ['0.1', '0.2', '0.3']
        Cartridge-Version: '0.0.1'
        Cartridge-Vendor: redhat
        Categories: 
          - web_framework
        Group-Overrides:
          - components:
            - crtest-0.3
            - web_proxy
        Version-Overrides:
          '0.1':
            Group-Overrides:
              - components:
                - crtest-0.1
                - web_proxy
          '0.2':
            Group-Overrides:
              - components:
                - crtest-0.2
                - web_proxy
      }
    assert manifests = OpenShift::Runtime::Manifest.manifests_from_yaml(manifest)
    assert_equal 3, manifests.length
    assert m = manifests[0]
    assert_equal '0.3', m.version
    assert_equal 'crtest', m.name
    carts = manifests.map{ |m| OpenShift::Cartridge.new.from_descriptor(m.manifest) }
    assert_equal [{'components' => ['crtest-0.3', 'web_proxy']}], carts[0].group_overrides
    assert_equal [{'components' => ['crtest-0.2', 'web_proxy']}], carts[1].group_overrides
    assert_equal [{'components' => ['crtest-0.1', 'web_proxy']}], carts[2].group_overrides
  end

  test "find and download from cartridges" do
    carts = CartridgeCache.find_and_download_cartridges(["ruby"])
    cart = CartridgeType.active.where(provides: 'ruby').first
    assert_equal 1, carts.length
    assert_equal cart.name, carts[0].name
    assert_nil carts[0].manifest_url
    assert carts[0].gear_size.nil?
    assert_equal cart._id, carts[0].id
    assert_equal cart.id, carts[0].id
  end

  test "find and download a cartridge" do
    CartridgeCache.expects(:download_from_url).with("manifest://test", "cartridge").returns(<<-MANIFEST.strip_heredoc)
      ---
      Name: mock
      Version: '0.1'
      Display-Name: Mock Cart
      Cartridge-Short-Name: MOCK
      Cartridge-Vendor: mock
      Categories:
      - mock
      - web_framework
      MANIFEST
    assert carts = CartridgeCache.find_and_download_cartridges([{url: 'manifest://test'}])
    assert_equal 1, carts.length
    assert cart = carts[0]
    assert CartridgeInstance === cart
    assert_equal "mock-mock-0.1", cart.name
    assert_equal "manifest://test", cart.manifest_url
    assert cart.id
    manifest = YAML.load(cart.manifest_text)
    assert_nil manifest['Manifest-Url']
    assert_equal cart.id, manifest['Id']
  end

  test "find and download a cartridge and select the preferred version" do
    CartridgeCache.expects(:download_from_url).with("manifest://test", "cartridge").returns(<<-MANIFEST.strip_heredoc)
      ---
      Name: mock
      Version: '0.1'
      Versions: ['0.1', '0.2']
      Display-Name: Mock Cart
      Cartridge-Short-Name: MOCK
      Cartridge-Vendor: mock
      Categories:
      - mock
      - web_framework
      MANIFEST
    assert carts = CartridgeCache.find_and_download_cartridges([{url: 'manifest://test'}])
    assert_equal 1, carts.length
    assert cart = carts[0]
    assert CartridgeInstance === cart
    assert_equal "mock-mock-0.1", cart.name
    assert_equal "manifest://test", cart.manifest_url
    assert cart.id
    manifest = YAML.load(cart.manifest_text)
    assert_nil manifest['Manifest-Url']
    assert_equal cart.id, manifest['Id']
  end

  test "use a stream to find a downloadable URL" do
    body = <<-MANIFEST.strip_heredoc
      ---
      Name: remotemock
      Version: '0.1'
      Display-Name: Mock Cart
      Cartridge-Short-Name: MOCK
      Cartridge-Vendor: mock
      Categories:
      - mock
      - web_framework
      Provides: foo
      MANIFEST
    CartridgeCache.expects(:download_from_url).with("manifest://test", "cartridge").returns(body)
    CartridgeType.where(:base_name => 'remotemock').delete
    types = CartridgeType.update_from(OpenShift::Runtime::Manifest.manifests_from_yaml(body), 'manifest://test')
    types.each(&:activate!)

    assert carts = CartridgeCache.find_and_download_cartridges([{name: 'remotemock'}])
    assert_equal 1, carts.length
    assert cart = carts[0]
    assert cart.singleton?
    assert CartridgeInstance === cart
    assert_equal "mock-remotemock-0.1", cart.name
    assert_equal "manifest://test", cart.manifest_url
    assert_equal types[0].id, cart.id
    manifest = YAML.load(cart.manifest_text)
    assert_nil manifest['Manifest-Url']
    assert_equal cart.id.to_s, manifest['Id']
  end

  test "find cartridge by id and user" do
    CloudUser.where(login: 'test_cart_cache').delete
    Application.where(name: 'test', domain_id: 'foo').delete
    user = CloudUser.create(login: 'test_cart_cache')
    id = Moped::BSON::ObjectId.new
    assert_nil CartridgeCache.find_cartridge_by_id_for_user(id, user)

    attributes = {'Name' => 'foo', 'Id' => id.to_s}
    cart = OpenShift::Cartridge.new(attributes, true)
    cart.manifest_text = attributes.to_json
    app = Application.new(name: 'test', domain_id: 'foo')
    app.component_instances << ComponentInstance.from(cart)
    app.save!
    assert_nil CartridgeCache.find_cartridge_by_id_for_user(id, user)

    app.add_members(user, :admin)
    app.save!
    assert cart = CartridgeCache.find_cartridge_by_id_for_user(id, user)
    assert_equal id.to_s, cart.id
   end

  test "find cartridge with hypothetical cartridges" do
    CartridgeType.where(provides: 'phpy').delete
    CartridgeType.update_from(OpenShift::Runtime::Manifest.manifests_from_yaml(<<-BODY.strip_heredoc)).each(&:activate!)
      ---
      Name: phpx
      Version: '5.3'
      Display-Name: PHPX
      Cartridge-Short-Name: MOCK
      Cartridge-Vendor: redhat
      Categories:
      - mock
      - web_framework
      Provides:
      - phpy
      BODY
    CartridgeType.update_from(OpenShift::Runtime::Manifest.manifests_from_yaml(<<-BODY.strip_heredoc)).each(&:activate!)
      ---
      Name: phpx
      Version: '5.3'
      Versions: ['5.3', '5.4']
      Display-Name: PHPX
      Cartridge-Short-Name: MOCK
      Cartridge-Vendor: other
      Categories:
      - mock
      - web_framework
      Provides:
      - phpy
      BODY
    CartridgeType.update_from(OpenShift::Runtime::Manifest.manifests_from_yaml(<<-BODY.strip_heredoc)).each(&:activate!)
      ---
      Name: phpx
      Version: '5.4'
      Display-Name: PHPX
      Cartridge-Short-Name: MOCK
      Cartridge-Vendor: third
      Categories:
      - mock
      - web_framework
      Provides:
      - phpy
      BODY
    cart = CartridgeCache.find_cartridge("phpx-5.3")
    assert cart.features.include? "phpy"
    assert cart.version, "5.3"
    assert_equal cart.cartridge_vendor, "redhat"

    assert cart = CartridgeCache.find_cartridge_by_base_name("phpx-5.3")
    assert cart.features.include? "phpy"
    assert cart.version, "5.3"
    assert_equal "redhat", cart.cartridge_vendor

    assert cart = CartridgeCache.find_cartridge_by_base_name("redhat-phpx-5.3")
    assert cart.features.include? "phpy"
    assert cart.version, "5.3"
    assert_equal cart.cartridge_vendor, "redhat"

    assert_nil CartridgeCache.find_cartridge("phpx-5.5")

    assert_nil CartridgeCache.find_cartridge_by_base_name("phpy")

    assert_raises(OpenShift::UserException){ CartridgeCache.find_cartridge_by_base_name("phpx-5.4") }
    begin
      CartridgeCache.find_cartridge_by_base_name("phpx-5.4")
    rescue => e
      s = e.to_s
      assert s =~ /More than one cartridge was found/, s
      assert s.include?('other-phpx-5.4'), s
      assert s.include?('third-phpx-5.4'), s
    end
  end

  test "find requires for cartridges" do
    mysql_carts = CartridgeType.active.provides('mysql').select{ |c| c.names.include?('mysql') }.sort_by(&OpenShift::Cartridge::NAME_PRECEDENCE_ORDER).map(&:name)
    assert_equal [mysql_carts], CartridgeCache.find_requires_for(OpenShift::Cartridge.new('Id' => 'test1', 'Requires' => ["mysql"]))
    assert_equal [mysql_carts], CartridgeCache.find_requires_for(OpenShift::Cartridge.new('Id' => 'test2', 'Requires' => ["redhat-mysql"]))
    assert_equal [["unknown"], mysql_carts], CartridgeCache.find_requires_for(OpenShift::Cartridge.new('Id' => 'test3', 'Requires' => ["unknown", "redhat-mysql"]))
    assert_equal [mysql_carts], CartridgeCache.find_requires_for(OpenShift::Cartridge.new('Id' => 'test4', 'Requires' => [nil, "redhat-mysql"]))
    assert_equal [], CartridgeCache.find_requires_for(OpenShift::Cartridge.new('Id' => 'test5', 'Requires' => [nil, []]))
  end

  test "find cartridge with real cartridges" do
    carts = CartridgeType.active
    carts.each do |cart|
      assert CartridgeCache.find_cartridge(cart.name), "Cartridge #{cart.name} not found"

      # CHANGED: Finding a cartridge by vendor and name might return multiple cartridges
      c = (CartridgeCache.find_cartridge_by_base_name("#{cart.cartridge_vendor}-#{cart.original_name}") rescue true)
      assert c.present?, "Cartridge #{cart.cartridge_vendor}-#{cart.original_name} not found"
    end
  end

  test "find all cartridges with hypothetical cartridges" do

    carts = []
    #redhat and another cartridge_vendor providing the same cartridge
    cart = OpenShift::Cartridge.new
    cart.name = "php-5.3"
    cart.cartridge_vendor = "redhat"
    cart.provides = ["php"]
    cart.version = "5.3"

    carts << cart
    cart = OpenShift::Cartridge.new
    cart.name = "php-5.3"
    cart.cartridge_vendor = "other"
    cart.provides = ["php"]
    cart.version = "5.3"
    carts << cart

    cart = OpenShift::Cartridge.new
    cart.name = "php-5.4"
    cart.cartridge_vendor = "other"
    cart.provides = ["php"]
    cart.version = "5.4"
    carts << cart

    # 2 different cartridge_vendors providing the same cartridge
    cart = OpenShift::Cartridge.new
    cart.name = "python-3.3"
    cart.cartridge_vendor = "other"
    cart.provides = ["python"]
    cart.version = "3.3"
    carts << cart

    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "another"
    cart.name = "python-3.3"
    cart.provides = ["python"]
    cart.version = "3.3"
    carts << cart

    #redhat has more than one version of cartridge
    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "redhat"
    cart.name = "ruby-1.8"
    cart.provides = ["ruby"]
    cart.version = "1.8"

    carts << cart
    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "redhat"
    cart.name = "ruby-1.9"
    cart.provides = ["ruby"]
    cart.version = "1.9"
    carts << cart

    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "other"
    cart.name = "ruby-1.10"
    cart.provides = ["ruby"]
    cart.version = "1.10"
    carts << cart

    CartridgeCache.stubs(:get_all_cartridges).returns(carts)

    carts = CartridgeCache.find_all_cartridges("php-5.3")
    carts.each do |cart|
      assert cart.features.include?"php"
      assert cart.version, "5.3"
    end

    carts = CartridgeCache.find_all_cartridges("redhat-php-5.3")
    carts.each do |cart|
      assert cart.features.include?"php"
      assert cart.version, "5.3"
      assert_equal cart.cartridge_vendor, "redhat"
    end

    carts = CartridgeCache.find_all_cartridges("php-5.4")
    carts.each do |cart|
      assert cart.features.include?"php"
      assert cart.version, "5.4"
    end

    carts = CartridgeCache.find_all_cartridges("ruby-1.9")
    carts.each do |cart|
      assert cart.features.include?"ruby"
      assert cart.version == "1.9"
    end
  end
end
