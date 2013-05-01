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
    cart.provides = ["php"]
    cart.version = "5.3"
    
    carts << cart
    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "other"
    cart.provides = ["php"]
    cart.version = "5.3"
    carts << cart
    
    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "other"
    cart.provides = ["php"]
    cart.version = "5.4"
    carts << cart
    
    # 2 different cartridge_vendors providing the same cartridge
    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "other"
    cart.provides = ["python"]
    cart.version = "3.3"
    carts << cart
    
    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "another"
    cart.provides = ["python"]
    cart.version = "3.3"    
    carts << cart
    
    #redhat has more than one version of cartridge
    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "redhat"
    cart.provides = ["ruby"]
    cart.version = "1.8"
    
    carts << cart
    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "redhat"
    cart.provides = ["ruby"]
    cart.version = "1.9"
    carts << cart
    
    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "other"
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
    
    #test for more that one match
    assert_raise(OpenShift::UserException){CartridgeCache.find_cartridge("python-3.3")}
    
    cart = CartridgeCache.find_cartridge("ruby-1.9")
    assert cart.features.include?"ruby"
    assert cart.version == "1.9"
    assert cart.cartridge_vendor, "redhat"
    
  end
  
  test "find cartridge with real cartridges" do 
    carts = CartridgeCache.cartridges
    carts.each do |cart|
      #puts "CART #{cart.name} #{cart.cartridge_vendor}-#{cart.name}-#{cart.version}  #{cart.features.to_s} #{cart.versions.to_s} #{cart.version}"
      c = CartridgeCache.find_cartridge(cart.name)
      assert !c.nil?
    end
  end


end