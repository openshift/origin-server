##
# Cartridge list API
# @api REST
class CartridgesController < BaseController
  skip_before_filter :authenticate_user!

  ##
  # Retrieve details for specific cartridge
  # 
  # URL: /cartridges/:id
  #
  # @note This method may or may not require authenticated access depending on the authentication plugin that is configured.  
  #
  # Action: GET
  # @return [RestReply<RestCartridge>] Cartridge Object
  def show
    index
  end

  ##
  # Retrieve details for all available cartridge
  # 
  # URL: /cartridges
  #
  # @note This method may or may not require authenticated access depending on the authentication plugin that is configured.  
  #
  # Action: GET
  # @return [RestReply<Array<RestCartridge>>] Array of cartridge objects
  def index
    type = params[:id]
    if type.nil?
      cartridges = CartridgeCache.cartridges
    else
      # handle "standalone" type for backwards compatibility
      type = "web_framework" if type == "standalone"
      cartridges = CartridgeCache.cartridges.keep_if{ |c| c.categories.include?(type) }
    end
    rest_cartridges = cartridges.map do |c|
      if requested_api_version == 1.0
        RestCartridge10.new(c)
      else
        RestCartridge.new(c)
      end
    end
    render_success(:ok, "cartridges", rest_cartridges, "List #{type.nil? ? 'all' : type} cartridges")
  end
  
  def set_log_tag
    @log_tag = get_log_tag_prepend + "CARTRIDGE"
  end
end
