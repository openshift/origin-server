require 'recaptcha'
require 'json'
include ActionView::Helpers::UrlHelper

class UserController < SiteController

  layout 'simple'

  before_filter :require_login, :only => :show
  protect_from_forgery :except => :create_external
  include DomainAware

  def skip_captcha?
    Rails.configuration.captcha_secret.presence and params[:captcha_secret] == Rails.configuration.captcha_secret
  end

  def new
    @product = 'openshift' unless defined? @product
    @redirect = params[:redirect].presence || params[:redirectUrl].presence
    @captcha_secret = params[:captcha_secret].presence

    @user = WebUser.new params[:web_user]
  end

  def create
    logger.debug "Registration request"

    @user = WebUser.new params[:web_user]
    @captcha_secret = params[:captcha_secret]

    # Run validations
    valid = @user.valid?

    logger.warn "Starting user creation: #{@user.email_address}"

    # See if the captcha secret was provided
    if skip_captcha?
      logger.warn "Captcha secret provided - ignoring captcha"
    elsif sauce_testing? #Checks for sauce_testing cookie and development Rails
      logger.warn "Sauce testing cookie provided - ignoring captcha"
    else
      @captcha_secret = nil
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

    # FIXME: Need to pass signin destination through confirmation link
    confirmationUrl = url_for(:action => 'confirm',
                              :controller => 'email_confirm',
                              :only_path => false,
                              :protocol => 'https')

    @user.register(confirmationUrl, @user.promo_code)

    logger.debug "Confirmation URL: #{confirmationUrl}"

    unless @user.errors.length == 0
      render :new and return
    end

    # Successful user registration event for analytics
    @event = 'event29'

    #Process promo code
    if @user.promo_code and not @user.promo_code.blank?
      PromoCodeMailer.promo_code_email(@user).deliver

      #Save promo code so that omniture tag can be updated in UserController::complete
      session[:promo_code] = @user.promo_code
    end

    redirect_to complete_account_path(:promo_code => @user.promo_code.presence)
  end

  def complete
    @event = 'event29' # set omniture 'simple registration' event

    if session[:promo_code]
      @event += ",event8"
      @evar8 = session[:promo_code]
      session.delete(:promo_code)
    end

    render :create
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

  def show
    @user = session_user
    @user.load_email_address
    logger.debug "  User: #{@user.inspect}"
    @identities = Identity.find(@user)
    @show_email = @identities.any? {|i| i.id != i.email }

    user_default_domain rescue nil

    @keys = Key.find(:all, :as => @user)
    render :layout => 'console'
  end

end
