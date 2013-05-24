ENV["TEST_NAME"] = "unit_cartridge_cache_test"
require 'test_helper'

class CartridgeCacheTest < ActiveSupport::TestCase
  def setup

  end
  
  test "find cartridge with hypothetical cartridges" do
    
    carts = []
    #redhat and another cartridge_vendor providing the same cartridge
    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "redhat"
    cart.name = "php-5.3"
    cart.provides = ["php"]
    cart.version = "5.3"
    
    carts << cart
    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "other"
    cart.name = "php-5.3"
    cart.provides = ["php"]
    cart.version = "5.3"
    carts << cart
    
    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "other"
    cart.name = "php-5.4"
    cart.provides = ["php"]
    cart.version = "5.4"
    carts << cart
    
    # 2 different cartridge_vendors providing the same cartridge
    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "other"
    cart.name = "python-3.3"
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

    CartridgeCache.stubs(:cartridges).returns(carts)
    
    cart = CartridgeCache.find_cartridge("php-5.3")
    assert cart.features.include?"php"
    assert cart.version, "5.3"
    assert_equal cart.cartridge_vendor, "redhat"
       
    cart = CartridgeCache.find_cartridge("redhat-php-5.3")
    assert cart.features.include?"php"
    assert cart.version, "5.3"
    assert_equal cart.cartridge_vendor, "redhat"
    
    cart = CartridgeCache.find_cartridge("php-5.4")
    assert cart.features.include?"php"
    assert cart.version, "5.4"

    cart = CartridgeCache.find_cartridge("php")
    assert cart.features.include?"php"
    
    #test for more that one match
    assert_raise(OpenShift::UserException){CartridgeCache.find_cartridge("python-3.3")}
    
    cart = CartridgeCache.find_cartridge("ruby-1.9")
    assert cart.features.include?"ruby"
    assert cart.version == "1.9"
    assert cart.cartridge_vendor, "redhat"
    
    Rails.cache.delete('carts_by_feature_python-3.3')
    Rails.cache.delete('carts_by_feature_php-5.3')
    Rails.cache.delete('carts_by_feature_redhat-php-5.3')
    Rails.cache.delete('carts_by_feature_php-5.4')
    Rails.cache.delete('carts_by_feature_ruby-1.8')
    Rails.cache.delete('carts_by_feature_ruby-1.9')
    Rails.cache.delete('carts_by_feature_ruby-1.10')

  end
  
  test "find cartridge with real cartridges" do 
    carts = CartridgeCache.cartridges
    carts.each do |cart|
      #puts "CART #{cart.name} #{cart.cartridge_vendor}-#{cart.features[0]}-#{cart.version}  #{cart.features.to_s} #{cart.versions.to_s} #{cart.version}"
      c = CartridgeCache.find_cartridge(cart.name)
      assert(!c.nil?, "Cartridge #{cart.name} not found")
      
      c = CartridgeCache.find_cartridge("#{cart.cartridge_vendor}-#{cart.original_name}")
      assert(!c.nil?, "Cartridge #{cart.cartridge_vendor}-#{cart.original_name} not found")
      
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

    CartridgeCache.stubs(:cartridges).returns(carts)
    
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
    
    Rails.cache.delete('carts_by_feature_python-3.3')
    Rails.cache.delete('carts_by_feature_php-5.3')
    Rails.cache.delete('carts_by_feature_redhat-php-5.3')
    Rails.cache.delete('carts_by_feature_php-5.4')
    Rails.cache.delete('carts_by_feature_ruby-1.8')
    Rails.cache.delete('carts_by_feature_ruby-1.9')
    Rails.cache.delete('carts_by_feature_ruby-1.10')
  end


end
