class CartridgeTypesController < ConsoleController
  include Console::ModelHelper
  include CostAware

  def index
    @application = Application.find(params[:application_id], :params => {:include => :cartridges}, :as => current_user)
    installed_carts = @application.cartridges

    types = CartridgeType.embedded(:as => current_user)

    @blocked = []

    @installed, types = types.partition{ |t| installed_carts.any?{ |c| c.name == t.name } }
    @blacklist, types = types.partition{ |t| t.tags.include?(:blacklist) }

    @conflicts, types = types.partition{ |t| conflicts? t }
    @requires, types  = types.partition{ |t| requires? t }

    @installed.sort!; @conflicts.sort!; @requires.sort!
    @carts = types.sort!
  end

  def show
    name = params[:id].presence
    url = params[:url].presence
    @wizard = !params[:direct].present?

    url = CartridgeType.normalize_url(url)

    @application = Application.find(params[:application_id], :as => current_user)
    @capabilities = @application.domain.capabilities
    @cartridge_type = url ? CartridgeType.for_url(url) : CartridgeType.cached.find(name)
    @gear_sizes = add_cartridge_gear_sizes(@application, @cartridge_type, @capabilities)
    @cartridge = Cartridge.new :as => current_user

    if @cartridge_type.valid_gear_sizes? && (@gear_sizes.map(&:to_sym) & @cartridge_type.valid_gear_sizes).empty?
      flash.now[:error] = "The gear sizes available for this application or your account are not compatible with this cartridge. #{@cartridge_type.display_name} can only run on the following gear sizes: #{@cartridge_type.valid_gear_sizes.map(&:to_s).join(', ')}."
    end
  end

  def estimate
    cart_params = params[:cartridge] || params

    name = cart_params[:name].presence
    url = cart_params[:url].presence
    gear_size = cart_params[:gear_size].presence

    application = Application.find(params[:application_id], :as => current_user)
    cartridge_type = url ? CartridgeType.for_url(url) : CartridgeType.cached.find(name)

    render :text => gear_increase_indicator({'1' => [cartridge_type]}, application.scales?, gear_size, true, application.domain.capabilities, application.domain.usage_rates, application.owner?)
  rescue => e
    logger.error $!
    render :text => "An error has occurred", :status => 500
  end

  def conflicts?(cart_type)
    t = cart_type

    return false if @installed.nil? || t.conflicts.empty?

    # if this cart can conflict and a conflicting cart is installed
    # add this cart to the conflicted list
    @installed.each { |c| return true if t.conflicts.include? c.name }
    return false
  end

  def requires?(cart_type)
    t = cart_type

    return true if @installed.nil? && !t.requires.blank?
    return false if t.requires.blank?

    # if this cart has requirements and the required cart is not
    # installed add this cart to the requires list
    @installed.each { |c| return false if t.requires.any?{ |r| r.include? c.name } }
    return true
  end


  protected
    def active_tab
      :applications
    end
end
