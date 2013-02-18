module CartridgeHelper
  def get_cartridges(application, domain)
    cartridges = []
    cartridges.push(RestEmbeddedCartridge.new("standalone", application.framework, application, domain, get_url, nil, nolinks)) if requested_api_version != 1.0

    application.embedded.each_key do |key|
      cartridge = if requested_api_version == 1.0
          RestEmbeddedCartridge10.new("embedded", key, application, domain, get_url, nil, nolinks)
        else
          RestEmbeddedCartridge.new("embedded", key, application, domain, get_url, nil, nolinks)
        end
      cartridges.push(cartridge)
    end if application.embedded
    cartridges
  end

  def check_cartridge_type(framework, container, cart_type)
    carts = CartridgeCache.cartridge_names(cart_type)
    Rails.logger.debug "Available cartridges #{carts.join(', ')}"
    unless carts.include? framework
      return false
    end
    true
  end
end
