class StorageController < ConsoleController
  before_filter :user_information
  before_filter :application_information

  def show
  end

  def update
    @cartridge = @application.find_cartridge(params[:id]) or raise RestApi::ResourceNotFound.new(Cartridge.model_name, params[:id])

    @cartridge.additional_gear_storage = Integer(params[:cartridge][:additional_gear_storage])

    if @cartridge.save
      redirect_to application_storage_path(@application), :flash => flash_messages(@cartridge.messages).merge({:success => "Updated storage for cartridge '#{@cartridge.display_name}'"})
    else
      flash.now[:error] = @cartridge.errors.messages.values.flatten
      render :show
    end
  end

  protected
    def active_tab
      :applications
    end  

  private
  def user_information
    @user = User.find :one, :as => current_user
  end

  def application_information
    @application = Application.find(params[:application_id], :as => current_user)
    @max_storage = @application.domain.capabilities.max_storage_per_gear || 0
    @usage_rates = @application.domain.usage_rates || {}
    @can_modify_storage = @max_storage > 0
    @gear_groups = @application.cartridge_gear_groups
  end
end
