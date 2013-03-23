class AliasesController < ConsoleController

  def index
    user_default_domain
    @capabilities = user_capabilities
    @application = @domain.find_application params[:application_id]
    @alias = Alias.new({ :application => @application, :as => current_user })
    @user = User.find :one, :as => current_user
    @private_ssl_certificates_supported = @user.capabilities["private_ssl_certificates"]
  end

  def show
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

    @alias.normalize_certificate_content!

    if @alias.save
      redirect_to @application, :flash => {:success => "Alias '#{@alias.id}' has been created"}
    else
      message = @alias.errors.first || "Unable to create alias '#{@alias.name}'"
      redirect_to application_aliases_path(@application), :flash => {:error => message.kind_of?(Array) ? message.select {|x| x.is_a?(String)} : message}
    end
  end

  def delete
    user_default_domain
    @application = @domain.find_application params[:application_id]
    @alias = params[:id]
  end

  def destroy
    @domain = Domain.find :one, :as => current_user
    @application = @domain.find_application params[:application_id]
    alias_name = params[:id]
    if alias_name and @application.remove_alias(alias_name)
      message = @application.messages.first || "Alias '#{alias_name}' has been removed"
      redirect_to @application, :flash => {:success => message.kind_of?(Array) ? message.select {|x| x.is_a?(String)} : message}
    else
      message = @alias.errors.first || "Unable to delete alias '#{alias_name}'"
      flash.now[:error] = message.kind_of?(Array) ? message.select {|x| x.is_a?(String)} : message
      render :index
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
      @alias.normalize_certificate_content!
      @alias.save if !@alias.certificate.nil?
    else
      @alias.save
    end

    if @alias.errors.empty?
      redirect_to @application, :flash => {:success => "Alias '#{@alias.id}' has been updated"}
    else
      message = @alias.errors.first || "Unable to update alias '#{@alias.name}'"
      flash.now[:error] = message.kind_of?(Array) ? message.select {|x| x.is_a?(String)} : message
      render :show
    end
  end
end
