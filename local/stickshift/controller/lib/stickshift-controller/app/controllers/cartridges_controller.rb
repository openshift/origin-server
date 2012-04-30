class CartridgesController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  include LegacyBrokerHelper
  
  def show
    index
  end
  
  # GET /cartridges
  def index
    type = params[:id]
    
    cartridges = Array.new
    if type.nil? or type == "standalone"
      cart_type = "standalone"
      cache_key = "cart_list_#{cart_type}"
      carts = get_cached(cache_key, :expires_in => 21600.seconds) do
        Application.get_available_cartridges(cart_type)
      end
      carts.each do |cart|
        cartridge = RestCartridge.new(cart_type, cart, nil, get_url)
        cartridges.push(cartridge)
      end
    end
    
    if type.nil? or type == "embedded"
      cart_type = "embedded"
      cache_key = "cart_list_#{cart_type}"
      carts = get_cached(cache_key, :expires_in => 21600.seconds) do
        Application.get_available_cartridges(cart_type)
      end
      carts.each do |cart|
        cartridge = RestCartridge.new(cart_type, cart, nil, get_url)
        cartridges.push(cartridge)
      end
    end
    
    @reply = RestReply.new(:ok, "cartridges", cartridges)
    respond_with @reply, :status => @reply.status
  end
end

