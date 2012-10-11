class ScalingController < ConsoleController

  def show
    user_default_domain
    @application = @domain.find_application params[:application_id]
    @cartridges = @application.cartridges
    @user = User.find :one, :as => current_user
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

  def update
    user_default_domain
    @application = @domain.find_application params[:application_id]
    @cartridge = Cartridge.new({
      :name => params[:id], 
      :application => @application
    }.merge(params[:cartridge].slice(:scales_from, :scales_to)), true)

    if @cartridge.save
      redirect_to application_scaling_path, :flash => {:success => "Updated scaling on #{@cartridge.display_name}"}
    else
      render :edit
    end
  end

  #def update
    # commit form parameters to a cartridge on an application
  #  redirect_to application_scaling_path
  #end
end
