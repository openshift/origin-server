class CartridgeCache
  def self.get_cached(key, opts={})
    unless Rails.configuration.action_controller.perform_caching
      if block_given?
        return yield
      end
    end

    val = Rails.cache.read(key)
    unless val
      if block_given?
        val = yield
        if val
          Rails.cache.write(key, val, opts)
        end
      end
    end

    return val
  end

  def self.cartridges
    get_cached("all_cartridges", :expires_in => 1.day) {OpenShift::ApplicationContainerProxy.find_one().get_available_cartridges}
  end

  def self.cartridge_names(cart_type=nil)
    cart_type = "web_framework" if cart_type == "standalone"
    cartridges.select{|c| cart_type.nil? or c.categories.include? cart_type}.map{|c| c.name}
  end

  def self.find_cartridge(capability)
    carts = self.cartridges
    carts.each do |cart|
      return cart if cart.all_capabilities.include?(capability)
      return cart if cart.name == capability
    end
    return nil
  end
end
