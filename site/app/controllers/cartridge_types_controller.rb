class CartridgeTypesController < ConsoleController

  def index
    @application_id = params[:application_id]

    @domain = Domain.first :as => session_user
    @application = @domain.find_application @application_id
 
    types = CartridgeType.find :all, {:as=> session_user}
    installed_carts = @application.cartridges

    @installed_cart_types = []
    installed_carts.each do |cart|
      installed_cart_type = types.find { |t| t.id == cart.name }
      if !installed_cart_type.nil?
        installed_cart_type.categories.push :installed
      end
    end

    # TODO: further categorization
    @installed_cart_types, types = types.partition { |t| t.categories.include?(:installed) }
    @blacklist_cart_types, types = types.partition { |t| t.categories.include?(:blacklist) }

    framework = ApplicationType.find(@application.framework)
    if framework.blocks
      @blocked_cart_types, types = types.partition { |t| framework.blocks.include?(t.id)}
    else
      @blocked_cart_types = []
    end

    @conflicts_cart_types, types = types.partition do |t|
      conflicts = conflicts? t
      t.categories.push('inactive') if conflicts

      conflicts
    end

    @requires_cart_types, types = types.partition do |t|
      requires = requires? t
      t.categories.push('inactive') if requires

      requires
    end

    @cart_types = types
  end

  def show
    @cartridge_type = CartridgeType.find params[:id], :as => session_user
    @application_id = params[:application_id]
    @cartridge = Cartridge.new :as => session_user
  end

  def conflicts?(cart_type)
    t = cart_type

    return false if @installed_cart_types.nil? || t.conflicts.empty?

    # if this cart can conflict and a conflicting cart is installed
    # add this cart to the conflicted list
    @installed_cart_types.each { |c| return true if t.conflicts.include? c.id }
    return false
  end

  def requires?(cart_type)
    t = cart_type

    return true if @installed_cart_types.nil? && !t.requires.empty?
    return false if t.requires.empty?

    # if this cart has requirements and the required cart is not
    # installed add this cart to the requires list
    @installed_cart_types.each { |c| return false if t.requires.include? c.id }
    return true
  end
end
