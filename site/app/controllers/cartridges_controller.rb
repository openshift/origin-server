class CartridgesController < ConsoleController

  def show
    @domain = Domain.first :as => session_user
    @application = @domain.find_application params[:application_id]
    @application_type = ApplicationType.find @application.framework
    @cartridge = @application.find_cartridge params[:id]
  end

end

