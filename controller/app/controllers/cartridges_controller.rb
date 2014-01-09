##
# Cartridge list API
# @api REST
class CartridgesController < BaseController
  include RestModelHelper
  skip_before_filter :authenticate_user!

  ##
  # Retrieve details for specific cartridge
  #
  # URL: /cartridge/:name
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
    searching = false
    carts = CartridgeType.active

    category = params[:category].presence || params[:id].presence
    category = 'web_framework' if category == 'standalone'
    if category == "embedded"
      searching = true
      carts = carts.not_in(categories: 'web_framework')
    elsif category
      searching = true
      carts = carts.in(categories: category)
    end
    if feature = params[:feature].presence
      searching = true
      carts = carts.in(provides: feature)
    end

    render_success(:ok, "cartridges", carts.map{ |c| get_rest_cartridge(c) }, "#{searching ? "Searching" : "Listing "} cartridges")
  end
end
