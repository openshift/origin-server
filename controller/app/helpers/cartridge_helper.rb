module CartridgeHelper
  def get_cartridges(application)
    cartridges = Array.new
    cartridges.push(RestCartridge.new("standalone", application.framework, application, get_url, nil, nolinks)) if $requested_api_version != 1.0

    application.embedded.each_key do |key|
      if $requested_api_version == 1.0
        cartridge = RestCartridge10.new("embedded", key, application, get_url, nil, nolinks)
      else
        cartridge = RestCartridge.new("embedded", key, application, get_url, nil, nolinks)
      end
      cartridges.push(cartridge)
    end if application.embedded
    return cartridges
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