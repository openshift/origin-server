class CartridgesController < BaseController

  skip_before_filter :authenticate_user!

  # FIXME: Should not do this
  def show
    index
  end

  # GET /cartridges
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
    render_success(:ok, "cartridges", rest_cartridges, "LIST_CARTRIDGES", "List #{type.nil? ? 'all' : type} cartridges")
  end
end
