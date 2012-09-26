class ScalingController < ConsoleController

  def show
    user_default_domain
    @application = @domain.find_application params[:application_id]
    redirect_to new_application_scaling_path(@application) unless @application.scales?
  end

  def new
    user_default_domain
    @application = @domain.find_application params[:application_id]
    @cartridge_type = CartridgeType.cached.find 'haproxy-1.4'
    @cartridge = Cartridge.new :name => @cartridge_type.name
  end

  def delete
    user_default_domain
    @application = @domain.find_application params[:application_id]
    redirect_to new_application_scaling_path(@application) unless @application.scales?
  end
end
