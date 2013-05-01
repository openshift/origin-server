class CartridgesController < ConsoleController

  def index
     # on index get, redirect back to application details page
     redirect_to application_path(params[:application_id])
  end

  def show
    @domain = user_default_domain

    @application = @domain.find_application params[:application_id]
    @application_type = ApplicationType.find @application.framework
    @cartridge = @application.find_cartridge params[:id]
  end

  def create
    name = (params[:cartridge] || {})[:name].presence
    url = (params[:cartridge] || {})[:url].presence
    
    @domain = user_default_domain
    @application = @domain.find_application params[:application_id]
    @cartridge_type = url ? CartridgeType.for_url(url) : CartridgeType.find(name)
    @cartridge = Cartridge.new(:url => url, :name => url ? nil : name, :as => current_user, :application => @application)

    if @cartridge.save
      @wizard = true

      message = @cartridge.remote_results
      flash.now[:info_pre] = message

      render :next_steps
    else
      Rails.logger.debug @cartridge.errors.inspect
      @application_id = @application.id
      render 'cartridge_types/show'
    end
  end
end

