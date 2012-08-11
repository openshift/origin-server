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
    get_cached("all_cartridges", :expires_in => 1.day) {ApplicationContainerProxy.find_one().get_available_cartridges}
  end

  def self.cartridge_names(cart_type=nil)
    cartridges.dup.delete_if{ |cart| !cart_type.nil? and !cart.categories.include?(cart_type) }.map{ |cart| cart.name }
  end

  def self.find_cartridge(feature)
    carts = self.cartridges
    carts.each do |cart|
      return cart if cart.features.include?(feature)
      return cart if cart.name == feature
    end
    return nil
  end
end
