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
    search = params[:id].presence
    # handle "standalone" type for backwards compatibility
    if search and search == "embedded" or search == "standalone"
      search = "web_framework" if search == "standalone"
      cartridges = CartridgeCache.cartridges.keep_if{ |c| c.categories.include?(search) }
      rest_cartridges = cartridges.map do |c|
        if requested_api_version == 1.0
          RestCartridge10.new(c)
        else
          RestCartridge.new(c)
        end
      end
      return render_success(:ok, "cartridges", rest_cartridges, "List #{search.nil? ? 'all' : search} cartridges")
    end
    # search by vendor, provides and version
    if search
      cartridges = CartridgeCache.find_all_cartridges(search)
      rest_cartridges = [] 
      cartridges.each do |c|
        if requested_api_version == 1.0
          rest_cartridges << RestCartridge10.new(c)
        else
          rest_cartridges << RestCartridge.new(c)
        end
      end if cartridges
      Rails.logger.error "cartridges #{rest_cartridges}"
      return render_success(:ok, "cartridges", rest_cartridges, "List #{search.nil? ? 'all' : search} cartridges")
    end
    # return all cartridges
    cartridges = CartridgeCache.cartridges
    rest_cartridges = cartridges.map do |c|
      if requested_api_version == 1.0
        RestCartridge10.new(c)
      else
        RestCartridge.new(c)
      end
    end
    render_success(:ok, "cartridges", rest_cartridges, "List #{search.nil? ? 'all' : search} cartridges")
  end
  
  def set_log_tag
    @log_tag = get_log_tag_prepend + "CARTRIDGE"
  end
end
