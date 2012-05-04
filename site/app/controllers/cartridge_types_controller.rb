class CartridgeTypesController < ConsoleController

  def index
    @domain = Domain.find :one, :as => session_user

    @application = @domain.find_application params[:application_id]
    installed_carts = @application.cartridges

    types = CartridgeType.embedded :as => session_user

    @installed = []
    installed_carts.each do |cart|
      installed_cart_type = types.find { |t| t.name == cart.name }
      if !installed_cart_type.nil?
        installed_cart_type.categories.push :installed
      end
    end

    # TODO: further categorization
    @framework = ApplicationType.find(@application.framework)
    if @framework.blocks
      @blocked, types = types.partition { |t| @framework.blocks.include?(t.name)}
    else
      @blocked = []
    end

    @installed, types = types.partition { |t| t.categories.include?(:installed) }
    @blacklist, types = types.partition { |t| t.categories.include?(:blacklist) }

    @conflicts, types = types.partition do |t|
      conflicts = conflicts? t
      t.categories.push('inactive') if conflicts

      conflicts
    end

    @requires, types = types.partition do |t|
      requires = requires? t
      t.categories.push('inactive') if requires

      requires
    end

    @carts = types
  end

  def show
    @domain = Domain.find :one, :as => session_user
    @application = @domain.find_application params[:application_id]

    @cartridge_type = CartridgeType.find params[:id], :as => session_user
    @cartridge = Cartridge.new :as => session_user
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
end
