class StorageController < ConsoleController
  before_filter :user_information
  before_filter :application_information

  def show
    @max_storage = @user.capabilities[:max_storage_per_gear] || 0
    @can_modify_storage = @max_storage > 0
  end

  def update
    @cartridge = @application.find_cartridge(params[:id]) or raise RestApi::ResourceNotFound.new(Cartridge.model_name, params[:id])

    @cartridge.additional_gear_storage = Integer(params[:cartridge][:additional_gear_storage])

    if @cartridge.save
      redirect_to application_storage_path, :flash => {:success => "Updated storage for cartridge '#{@cartridge.display_name}'"}
    else
      #FIXME: Should this be handled automatically?
      errors =  @cartridge.errors.messages.values.flatten
      redirect_to application_storage_path, :flash => {:error => errors }
    end
  end

  private
  def user_information
    user_default_domain
    @user = User.find :one, :as => current_user
  end

  def application_information
    @application = @domain.find_application params[:application_id]
    @gear_groups = @application.cartridge_gear_groups
  end
end
