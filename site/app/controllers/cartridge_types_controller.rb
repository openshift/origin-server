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
    @cart_types = types
  end

  def show
    @cartridge_type = CartridgeType.find params[:id], :as => session_user
    @application_id = params[:application_id]
    @cartridge = Cartridge.new :as => session_user
  end
end
