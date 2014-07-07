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
    id = params[:id].presence
    if id == "embedded" or id == "standalone"
      #for backward compatibility get all cartridges matching
      index

    else
      c = if id? id
        CartridgeCache.find_cartridge_by_id(id)
      else
        CartridgeCache.find_cartridge(CartridgeType.check_name!(id))
      end or raise Mongoid::Errors::DocumentNotFound.new(CartridgeType, name: id)

      render_success(:ok, "cartridge", get_rest_cartridge(c), "Cartridge #{c.name} found")
    end
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
    carts = CartridgeType.all
    if name = params[:name].presence
      if (ComponentInstance.check_name!(name) rescue nil)
        carts = carts.order_by(:name => 1).where(name: name)
      else
        carts = []
      end
    else
      carts = carts.active.order_by(:name => 1)
      #filter out obsolete cartridges for versions >= 1.7
      carts = carts.not_in(obsolete: true) if requested_api_version >= 1.7 and !Rails.configuration.openshift[:allow_obsolete_cartridges]
      # Legacy support for cartridges/standalone|embedded
      feature = params[:feature].presence
      category = params[:category].presence || params[:id].presence
      if ['standalone','embedded'].include?(feature)
        category = feature
        feature = nil
      end

      category = 'web_framework' if category == 'standalone'
      if category == "embedded"
        searching = true
        carts = carts.not_in(categories: 'web_framework')
      elsif category
        searching = true
        carts = carts.in(categories: category)
      elsif features = feature || params[:features].presence
        searching = true
        carts = carts.in(provides: features)
      end
    end

    carts = filter_carts_by_user_capability(carts)
    carts = carts.sort_by(&OpenShift::Cartridge::NAME_PRECEDENCE_ORDER)

    render_success(:ok, "cartridges", carts.map{ |c| get_rest_cartridge(c) }, "#{searching ? "Searching" : "Listing"} cartridges")
  end

  ##
  # Filter list of cartridges to omit cartridges that the user cannot use based on system configuration
  # If the user is not known, no filter is applied
  # @return [<Cartridge>] Array of cartridge objects
  def filter_carts_by_user_capability(carts)
    filtered_carts = carts
    cart_config = Rails.application.config.openshift[:cartridge_gear_sizes]
    if cart_config.any?
      current_user = optionally_authenticate_user!(false)
      if current_user
        allowed_gear_sizes = current_user.capabilities["gear_sizes"]
        Domain.accessible(current_user).each do |domain|
          allowed_gear_sizes = allowed_gear_sizes | domain.allowed_gear_sizes
        end
        filtered_carts = []
        carts.each do |cart|
          valid_gear_sizes = cart_config[cart.name]
          filtered_carts.push(cart) if valid_gear_sizes.empty? || (valid_gear_sizes & allowed_gear_sizes).any?
        end
      end
    end
    filtered_carts
  end

  private :filter_carts_by_user_capability

end
