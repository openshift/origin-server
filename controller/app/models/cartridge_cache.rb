# Cache of cartridge manifest metadata. Used to reduce the number of calls 
# to the Node to retrieve cartridge information.
class CartridgeCache
  include CacheHelper
  
  # Returns an Array of Cartridge objects
  def self.cartridges
    CacheHelper.get_cached("all_cartridges", :expires_in => 1.day) { ::OpenShift::ApplicationContainerProxy.find_one().get_available_cartridges }
  end

  # Returns an Array of cartridge names.
  #
  # == Parameters:
  # cart_type::
  #   Specify to return only names of cartridges which have specified cartridge categories
  def self.cartridge_names(cart_type=nil)
    if cart_type.nil?
      CacheHelper.get_cached("cart_names_all", :expires_in => 1.day) { cartridges.map{ |cart| cart.name } }
    else
      cart_type = "web_framework" if cart_type == "standalone"
      find_cartridge_by_category(cart_type).map{ |cart| cart.name }
    end
  end
  
  def self.find_cartridge_by_component(component_name)
    carts = self.cartridges
    carts.each do |cart|
      return cart if cart.has_component?(component_name)
      return cart if cart.name == component_name
    end
    return nil
  end
  
  def self.find_cartridge_by_category(cat)
    CacheHelper.get_cached("cartridges_by_cat_#{cat}", :expires_in => 1.day) {cartridges.select{|cart| cart.categories.include?(cat) }}
  end

  # Returns the first cartridge that provides the specified feature.
  # @note This method matches both features provided by the cartridge as well as the cartridge name.
  #
  # == Parameters:
  # feature::
  #   Name of feature to look for.
  def self.find_cartridge(feature)
    carts = self.cartridges
    carts.each do |cart|
      return cart if cart.features.include?(feature)
      return cart if cart.name == feature
    end
    return nil
  end
end
