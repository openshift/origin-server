class CartridgeTypesController < ConsoleController
  

  def index
    app_id = params[:application_id]
    types = CartridgeType.find :all, {:as=> session_user}
    @cart_types = types
    # TODO: add categories
    #@cart_types, types = types.partition { |t| t.categories.include?(:storage) }
  end

  def show
    #@application_type = ApplicationType.find params[:id]
    #@domain = Domain.find :first, :as => session_user
    #@application = Application.new :as => session_user
  end
end
