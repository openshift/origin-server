class AliasesController < ConsoleController

  def new
    user_default_domain
    @capabilities = user_capabilities
    @application = @domain.find_application params[:application_id]
    @alias = Alias.new({ :application => @application, :as => current_user })
    @user = User.find :one, :as => current_user
    @private_ssl_certificates_supported = @user.capabilities["private_ssl_certificates"]
  end

  def edit
    user_default_domain
    @capabilities = user_capabilities
    @application = @domain.find_application params[:application_id]
    @user = User.find :one, :as => current_user
    @private_ssl_certificates_supported = @user.capabilities["private_ssl_certificates"]
    @alias = @application.find_alias params[:id]
  end

  def create
    user_default_domain
    @application = @domain.find_application(params[:application_id])
    @user = User.find :one, :as => current_user
    @private_ssl_certificates_supported = @user.capabilities["private_ssl_certificates"]

    @alias = Alias.new params[:alias]
    @alias.as = current_user
    @alias.application = @application

    if @alias.save
      redirect_to @application, :flash => {:success => "Alias '#{@alias.id}' has been created"}
    else
      flash.now[:error] = "Unable to create alias '#{@alias.name}'"
      render :new
    end
  rescue ActiveResource::ResetConnectionError => e
    raise unless Rails.env.test? || Rails.env.devenv? || Rails.env.development?
    @alias = @application.find_alias params[:alias][:id]
    redirect_to @application, :flash => {:success => "Alias '#{@alias.id}' has been created"}
  end

  def delete
    user_default_domain
    @application = @domain.find_application params[:application_id]
    @alias = params[:id]
  end

  def destroy
    @domain = Domain.find :one, :as => current_user
    @application = @domain.find_application params[:application_id]
    @alias = @application.find_alias params[:id]
    if @alias.destroy
      message = "Alias '#{params[:id]}' has been removed"
      redirect_to @application, :flash => {:success => message.to_s}
    else
      flash.now[:error] = "Unable to delete alias '#{alias_name}'"
      render :edit
    end
  end

  def update
    user_default_domain
    @application = @domain.find_application params[:application_id]
    @user = User.find :one, :as => current_user
    @private_ssl_certificates_supported = @user.capabilities["private_ssl_certificates"]
    @alias = @application.find_alias params[:id]

    if params[:alias]
      @alias.certificate_file = params[:alias][:certificate_file]
      @alias.certificate_private_key_file = params[:alias][:certificate_private_key_file]
      @alias.certificate_pass_phrase = params[:alias][:certificate_pass_phrase]
      @alias.save if !@alias.certificate.nil?
    else
      @alias.save
    end

    if @alias.errors.empty?
      redirect_to @application, :flash => {:success => "Alias '#{@alias.id}' has been updated"}
    else
      flash.now[:error] = "Unable to update alias '#{@alias.name}'"
      render :edit and return
    end
  end
end
