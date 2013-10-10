class CartridgeTypesController < ConsoleController

  include CostAware

  def index
    @application = Application.find(params[:application_id], :params => {:include => :cartridges}, :as => current_user)
    installed_carts = @application.cartridges

    types = CartridgeType.cached.embedded

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

    @capabilities = user_capabilities
    @application = Application.find(params[:application_id], :as => current_user)
    @cartridge_type = url ? CartridgeType.for_url(url) : CartridgeType.cached.find(name)
    @cartridge = Cartridge.new :as => current_user
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

    return true if @installed.nil? && !t.requires.empty?
    return false if t.requires.empty?

    # if this cart has requirements and the required cart is not
    # installed add this cart to the requires list
    @installed.each { |c| return false if t.requires.include? c.name }
    return true
  end

  
  protected
    def active_tab
      :applications
    end   
end
