class ScalingController < ConsoleController

  def show
    @application = Application.find(params[:application_id], :as => current_user)
    @cartridges = @application.cartridges.sort
    @user = User.find :one, :as => current_user
    redirect_to new_application_scaling_path(@application) unless @application.scales?
  end

  def new
    @application = Application.find(params[:application_id], :as => current_user)
  end

  def delete
    @application = Application.find(params[:application_id], :as => current_user)
    redirect_to new_application_scaling_path(@application) unless @application.scales?
  end

  def update
    @user = User.find :one, :as => current_user
    @application = Application.find(params[:application_id], :as => current_user)
    @cartridges = @application.cartridges.sort
    @cartridge = @cartridges.find{ |c| c.name == params[:id] } or raise RestApi::ResourceNotFound.new(Cartridge.model_name, params[:id])

    range = [params[:cartridge][:scales_from].to_i, params[:cartridge][:scales_to].to_i]
    range.reverse! if range.first > range.last && range.last != -1
    @cartridge.scales_from, @cartridge.scales_to = range

    if @cartridge.save
      redirect_to application_scaling_path, :flash => flash_messages(@cartridge.messages).merge({:success => "Updated scale settings for cartridge '#{@cartridge.display_name}'"})
    else
      render :show
    end
  end

  #def update
    # commit form parameters to a cartridge on an application
  #  redirect_to application_scaling_path
  #end
  
  protected
    def active_tab
      :applications
    end  
end
