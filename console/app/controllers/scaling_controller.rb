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
    @user = User.find :one, :as => current_user
    @application = @domain.find_application params[:application_id]
    @cartridges = @application.cartridges
    @cartridge = @cartridges.find{ |c| c.name == params[:id] } or raise RestApi::ResourceNotFound.new(Cartridge.model_name, params[:id])

    range = [params[:cartridge][:scales_from].to_i, params[:cartridge][:scales_to].to_i]
    range.reverse! if range.first > range.last && range.last != -1
    @cartridge.scales_from, @cartridge.scales_to = range

    if @cartridge.save
      redirect_to application_scaling_path, :flash => {:success => "Updated scale settings for cartridge '#{@cartridge.display_name}'"}
    else
      render :show
    end
  end

  #def update
    # commit form parameters to a cartridge on an application
  #  redirect_to application_scaling_path
  #end
end
