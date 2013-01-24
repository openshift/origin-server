class CartridgesController < BaseController
  respond_to :xml, :json
  before_filter :check_version
  def show
    index
  end

  # GET /cartridges
  def index
    type = params[:id]
    if type.nil?
      cartridges = CartridgeCache.cartridges
    else
      cartridges = CartridgeCache.cartridges.keep_if{ |c| c.categories.include?(type) }
    end
    rest_cartridges = []
    cartridges.map! do |c|
      if $requested_api_version == 1.0
        rest_cartridges.push(RestCartridge10.new(c))
      else
        rest_cartridges.push(RestCartridge.new(c))
      end
    end
    render_success(:ok, "cartridges", rest_cartridges, "LIST_CARTRIDGES", "List #{type.nil? ? 'all' : type} cartridges")
  end
end
