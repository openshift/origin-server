ENV["TEST_NAME"] = "unit_cartridge_cache_test"
require 'test_helper'

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

  test "find and download from cartridges" do
    stub_cartridges
    carts = CartridgeCache.find_and_download_cartridges(["ruby"])
    assert_equal 1, carts.length
    assert_equal "ruby-1.9", carts[0].name
    assert_nil carts[0].manifest_url
    assert_nil carts[0].manifest_text
    assert carts[0].gear_size.nil?
  end

  test "find and download a cartridge" do
    CartridgeCache.expects(:download_from_url).with("manifest://test").returns(<<-MANIFEST.strip_heredoc)
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
  end

  test "find and download a cartridge and select the preferred version" do
    CartridgeCache.expects(:download_from_url).with("manifest://test").returns(<<-MANIFEST.strip_heredoc)
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
      MANIFEST
    CartridgeCache.expects(:download_from_url).with("manifest://test").returns(body)
    CartridgeType.where(:name => 'remotemock').delete
    type = CartridgeType.from_manifest(OpenShift::Runtime::Manifest.manifests_from_yaml(body), 'manifest://test')
    type.save!

    assert carts = CartridgeCache.find_and_download_cartridges([{name: 'remotemock'}])
    assert_equal 1, carts.length
    assert cart = carts[0]
    assert CartridgeInstance === cart
    assert_equal "mock-remotemock-0.1", cart.name
    assert_equal "manifest://test", cart.manifest_url
  end

  test "find cartridge with hypothetical cartridges" do
    stub_cartridges

    cart = CartridgeCache.find_cartridge("php-5.3")
    assert cart.features.include?"php"
    assert cart.version, "5.3"
    assert_equal cart.cartridge_vendor, "redhat"

    cart = CartridgeCache.find_cartridge("redhat-php-5.3")
    assert cart.features.include?"php"
    assert cart.version, "5.3"
    assert_equal cart.cartridge_vendor, "redhat"

    # CHANGE: Unless a cartridge exposes a "provides" with the exact version,
    #   non redhat cartridges will not be located
    assert cart = CartridgeCache.find_cartridge("php-5.4")
    assert cart.features.include?"php"
    assert cart.version, "5.4"
    assert_not_equal cart.cartridge_vendor, "redhat"

    cart = CartridgeCache.find_cartridge("php-5.5")
    assert cart.features.include? "php"
    assert cart.version, "5.5"

    cart = CartridgeCache.find_cartridge("php")
    assert cart.features.include?"php"

    assert_raise(OpenShift::UserException){CartridgeCache.find_cartridge("python-3.3")}

    cart = CartridgeCache.find_cartridge("ruby-1.9")
    assert cart.features.include?"ruby"
    assert cart.version == "1.9"
    assert cart.cartridge_vendor, "redhat"
  end

  test "find cartridge with real cartridges" do
    carts = CartridgeCache.cartridges
    carts.each do |cart|
      #puts "CART #{cart.name} #{cart.cartridge_vendor}-#{cart.features[0]}-#{cart.version}  #{cart.features.to_s} #{cart.versions.to_s} #{cart.version}"
      c = CartridgeCache.find_cartridge(cart.name)
      assert(!c.nil?, "Cartridge #{cart.name} not found")

      # CHANGED: Finding a cartridge by vendor and name might return multiple cartridges
      c = (CartridgeCache.find_cartridge("#{cart.cartridge_vendor}-#{cart.original_name}") rescue true)
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
