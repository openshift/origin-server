class ScalingController < ConsoleController

  def show
    user_default_domain
    @application = @domain.find_application params[:application_id]
    @gear_groups = @application.gear_groups
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
    @gear_group = @application.gear_groups.find{ |g| g.exposes? params[:id] }
    @cartridge = Cartridge.new({:name => params[:id], :application => @application}, true)
    @cartridge.scales_from, @cartridge.scales_to = [
      params[:cartridge][:scales_from], 
      params[:cartridge][:scales_to]
    ].sort

    if @cartridge.save
      redirect_to application_scaling_path
    else
      render :edit
    end
  end

  #def update
    # commit form parameters to a cartridge on an application
  #  redirect_to application_scaling_path
  #end
end
