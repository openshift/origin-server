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
    get_cached("all_cartridges", :expires_in => 21600.seconds) do
      OpenShift::ApplicationContainerProxy.find_one().get_available_cartridges
    end
  rescue OpenShift::NodeException => e
    Rails.logger.error <<-"ERROR"
    In #{__FILE__} cartridges method:
      Error while querying cartridge list. This may be because no node hosts responded.
      Please ensure you have installed node hosts and they are responding to "mco ping".
      Exception was: #{e.inspect}
    ERROR
    return [ ]
  end

  FRAMEWORK_CART_NAMES = ["python-2.6", "jenkins-1.4", "ruby-1.8", "ruby-1.9",
                          "diy-0.1", "php-5.3", "jbossas-7", "jbosseap-6.0", "jbossews-1.0",
                          "perl-5.10", "nodejs-0.6", "zend-5.6"
                         ]
  def self.cartridge_names(cart_type=nil)
    cart_names = cartridges.map{|c| c.name}

    if cart_type == 'standalone'
      return cart_names & FRAMEWORK_CART_NAMES
    elsif cart_type == 'embedded'
      return (cart_names - FRAMEWORK_CART_NAMES)
    else
      return cart_names
    end
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
