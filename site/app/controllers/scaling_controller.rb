class ScalingController < ConsoleController

  def show
    @domain = Domain.find :one, :as => session_user
    @application = @domain.find_application params[:application_id]
    redirect_to new_application_scaling_path(@application) unless @application.scales?
  end

  def new
    @domain = Domain.find :one, :as => session_user
    @application = @domain.find_application params[:application_id]
    @cartridge_type = CartridgeType.cached.find 'haproxy-1.4', :as => session_user
    @cartridge = Cartridge.new :name => @cartridge_type.name
  end

  def delete
    @domain = Domain.find :one, :as => session_user
    @application = @domain.find_application params[:application_id]
    redirect_to new_application_scaling_path(@application) unless @application.scales?
  end
end
