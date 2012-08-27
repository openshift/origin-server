class UserController < Console::UserController

  protect_from_forgery :except => :create_external

  def new
    @product = 'openshift' unless defined? @product
    @user = WebUser.new params[:web_user]
  end

  def create
    logger.debug "Registration request"

    @user = WebUser.new params[:web_user]

    # Run validations
    valid = @user.valid?

    logger.warn "Starting user creation: #{@user.email_address}"
    
    # See if the captcha secret was provided
    if params[:captcha_secret] == Rails.configuration.captcha_secret
      logger.warn "Captcha secret provided - ignoring captcha"
    elsif sauce_testing? #Checks for sauce_testing cookie and development Rails
      logger.warn "Sauce testing cookie provided - ignoring captcha"
    else
      logger.debug "Checking captcha"
      # Verify the captcha
      unless verify_recaptcha
        logger.debug "Captcha check failed"
        valid = false
        flash.delete(:recaptcha_error) # prevent the default flash from recaptcha gem
        @user.errors[:captcha] = "Captcha text didn't match"
      end
    end
    
    # Verify product choice if any
    @product = 'openshift'
    action = 'confirm'
    if @user.cloud_access_choice
      case @user.cloud_access_choice.to_i
      when CloudAccess::EXPRESS
        @product = 'express'
      end
    end
    
    # flash[:product] = @product

    # Stop if you have a validation error
    unless valid
      respond_to do |format|
        format.js { render :json => @user.errors and return }
        format.html { render 'new', :layout => 'simple' and return }
      end
    end

    confirmationUrl = url_for(:action => 'confirm',
                              :controller => 'email_confirm',
                              :only_path => false,
                              :protocol => 'https')

    @user.register(confirmationUrl)
    
    logger.debug "Confirmation URL: #{confirmationUrl}"

    unless @user.errors.length == 0
      respond_to do |format|
        format.js { render :json => @user.errors }
        format.html { render :new, :layout => 'simple' }
      end
      return
    end

    # Successful user registration event for analytics
    @event = 'event29'

    #Process promo code
    if @user.promo_code and not @user.promo_code.blank?
      PromoCodeMailer.promo_code_email(@user).deliver
      
      #Save promo code so that omniture tag can be updated in UserController::complete
      session[:promo_code] = @user.promo_code
    end

    redirect_url = params[:redirectUrl]
    if redirect_url
      # Redirect to a running workflow if it exists
      respond_to do |format|
        format.js { render :json => {:redirectUrl => redirect_url} }
        format.html { redirect_to redirect_url }
      end
    end
  end

  def complete
    @event = 'event29' # set omniture 'simple registration' event

    if session[:promo_code]
      @event += ",event8"
      @evar8 = session[:promo_code]
      session.delete(:promo_code)
    end

    render :create, :layout => 'simple'
  end

  def create_json_error_hash(user_errors)
    errors = {}
    user_errors.keys.each do |key|
      errors[key] = user_errors[key]
    end
    errors
  end

  def create_external
    logger.debug "External registration request"

    data = JSON.parse(params[:json_data])
      
    @user = WebUser.new(data)
      
    registration_referrer = params[:registration_referrer]
    if !registration_referrer
      json = JSON.generate({:errors => {:registration_referrer => ['registration_referrer not provided']}})
      render :json => json, :status => :bad_request and return
    end

    # Run validations
    if !@user.valid?
      json = JSON.generate({:errors => create_json_error_hash(@user.errors)})
      render :json => json, :status => :bad_request and return
    end
    
    if params[:captcha_secret] != Rails.configuration.captcha_secret
      render :nothing => true, :status => :unauthorized and return
    end

    begin
      confirmationUrl = url_for(:action => 'confirm_external',
                                :controller => 'email_confirm',
                                :only_path => false,
                                :registration_referrer => registration_referrer,
                                :protocol => 'https')
      @user.register(confirmationUrl)
    rescue Exception => e
      json = JSON.generate({:errors => {:base => [e.message]}})
      render :json => json, :status => :internal_server_error and return
    end
    
    if @user.errors.length == 0
      json = JSON.generate({:result => "Check your inbox for an email with a validation link. Click on the link to complete the registration process."})
      render :json => json and return
    else
      json = JSON.generate({:errors => create_json_error_hash(@user.errors)})
      render :json => json, :status => :internal_server_error and return
    end
  end
end
