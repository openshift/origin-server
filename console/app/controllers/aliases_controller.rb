class AliasesController < ConsoleController

  def index
    @capabilities = user_capabilities
    @application = Application.find(params[:application_id], :as => current_user)
    redirect_to new_application_alias_path(@application) and return if @application.aliases.blank?
    @private_ssl_certificates_supported = @application.domain.capabilities.private_ssl_certificates
  end

  def new
    @capabilities = user_capabilities
    @application = Application.find(params[:application_id], :as => current_user)
    @alias = Alias.new({ :application => @application, :as => current_user })
    @private_ssl_certificates_supported = @application.domain.capabilities.private_ssl_certificates
  end

  def edit
    @capabilities = user_capabilities
    @application = Application.find(params[:application_id], :as => current_user)
    @private_ssl_certificates_supported = @application.domain.capabilities.private_ssl_certificates
    @alias = @application.find_alias params[:id]
  end

  def create
    @application = Application.find(params[:application_id], :as => current_user)
    @private_ssl_certificates_supported = @application.domain.capabilities.private_ssl_certificates

    @alias = Alias.new params[:alias]
    @alias.as = current_user
    @alias.application = @application

    if @alias.save
      redirect_to @application, :flash => flash_messages(@alias.messages).merge({:success => "Alias '#{@alias.id}' has been created"})
    else
      render :new
    end
  rescue ActiveResource::ResetConnectionError => e
    raise unless Rails.env.test? || Rails.env.devenv? || Rails.env.development?
    @alias = @application.find_alias params[:alias][:id]
    redirect_to @application, :flash => flash_messages(@alias.messages).merge({:success => "Alias '#{@alias.id}' has been created"})
  end

  def delete
    @application = Application.find(params[:application_id], :as => current_user)
    @alias = @application.find_alias(params[:alias_id].presence || params[:id].presence)
  end

  def destroy
    @application = Application.find(params[:application_id], :as => current_user)
    @alias = @application.find_alias params[:id]
    if @alias.destroy
      message = "Alias '#{params[:id]}' has been removed"
      redirect_to @application, :flash => flash_messages(@alias.messages).merge({:success => message.to_s})
    else
      render :delete
    end
  end

  def update
    @application = Application.find(params[:application_id], :as => current_user)
    @private_ssl_certificates_supported = @application.domain.capabilities.private_ssl_certificates
    @alias = @application.find_alias params[:id]

    if params[:alias]
      @alias.certificate_file = params[:alias][:certificate_file]
      @alias.certificate_private_key_file = params[:alias][:certificate_private_key_file]
      @alias.certificate_pass_phrase = params[:alias][:certificate_pass_phrase]
      redirect_to @application and return if @alias.certificate.nil?
    end

    if @alias.save
      redirect_to @application, :flash => flash_messages(@alias.messages).merge({:success => "Alias '#{@alias.id}' has been updated"})
    else
      render :edit
    end
  end

  protected
    def active_tab
      :applications
    end
end
