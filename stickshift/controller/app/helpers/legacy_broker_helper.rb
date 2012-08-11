module LegacyBrokerHelper
  def get_cached(key, opts={})
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
  
  def check_cartridge_type(framework, container, cart_type)
    carts = CartridgeCache.cartridge_names(cart_type)
    Rails.logger.debug "Available cartridges #{carts.join(', ')}"
    unless carts.include? framework
      return false
    end
    return true
  end
end
