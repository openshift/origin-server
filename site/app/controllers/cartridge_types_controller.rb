class CartridgeTypesController < ConsoleController
  

  def index
    @application_id = params[:application_id]
    types = CartridgeType.find :all, {:as=> session_user}
    @cart_types = types
    # TODO: add categories
    #@cart_types, types = types.partition { |t| t.categories.include?(:storage) }
  end

  def show
    @cartridge_type = CartridgeType.find params[:id], :as => session_user
    @application_id = params[:application_id]
    @cartridge = Cartridge.new :as => session_user
  end
end
