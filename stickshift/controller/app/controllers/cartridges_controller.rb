class CartridgesController < BaseController
  respond_to :xml, :json
  before_filter :check_version
  include LegacyBrokerHelper
  
  def show
    index
  end
  
  # GET /cartridges
  def index
    type = params[:id]
    log_action(@request_id, @cloud_user._id, @cloud_user.login, "LIST_CARTRIDGES", true, "List #{type.nil? ? 'all' : type} cartridges")
    
    cartridges = Array.new
    if type.nil? or type == "standalone"
      cache_key = "cart_list_standalone"
      carts = get_cached(cache_key, :expires_in => 21600.seconds) do
        CartridgeCache.cartridges.delete_if{ |c| !c.categories.include? "web_framework" }
      end
      carts.each do |cart|
        if $requested_api_version >= 1.1
          cartridge = RestCartridge11.new("standalone", cart, nil, get_url, nolinks)
        else
          cartridge = RestCartridge10.new("standalone", cart, nil, get_url, nolinks)
        end
        cartridges.push(cartridge)
      end
    end
    
    if type.nil? or type == "embedded"
      cache_key = "cart_list_embedded"
      carts = get_cached(cache_key, :expires_in => 21600.seconds) do
        CartridgeCache.cartridges.delete_if{ |c| c.categories.include? "web_framework" }
      end
      carts.each do |cart|
	      if $requested_api_version >= 1.1
          cartridge = RestCartridge11.new("embedded", cart, nil, get_url, nolinks)
        else
          cartridge = RestCartridge10.new("embedded", cart, nil, get_url, nolinks)
        end
        cartridges.push(cartridge)
      end
    end
    render_success(:ok, "cartridges", cartridges, "LIST_CARTRIDGES", "List #{type.nil? ? 'all' : type} cartridges") 
  end
end
