require 'pp'
require 'net/http'
require 'net/https'
require 'recaptcha'
require 'json'
require 'yaml'

class UserController < ApplicationController
  
  protect_from_forgery :except => :create_external

  def new(cloud_access_choice=nil)
    @product = 'openshift' unless defined? @product
    render :new and return
  end

  def new_flex
    @product = 'flex'
    new(CloudAccess::FLEX)
  end

  def new_express
    @product = 'express'
    new(CloudAccess::EXPRESS)
  end

  def create
    Rails.logger.debug "Registration request"

    @user = WebUser.new(params[:web_user])

    # Run validations
    valid = @user.valid?

    # See if the captcha secret was provided
    if Rails.configuration.integrated
      if params[:captcha_secret] == Rails.configuration.captcha_secret
        Rails.logger.warn "Captcha secret provided - ignoring captcha"
      elsif sauce_testing? #Checks for sauce_testing cookie and development Rails
        Rails.logger.warn "Sauce testing cookie provided - ignoring captcha"
      else
        Rails.logger.debug "Checking captcha"
        # Verify the captcha
        unless verify_recaptcha
          Rails.logger.debug "Captcha check failed"
          valid = false
          @user.errors[:captcha] = "Captcha text didn't match"
        end
      end
    else
      Rails.logger.warn "Non-integrated environment - ignoring captcha"
    end
    
    # Verify product choice if any
    @product = 'openshift'
    action = 'confirm'
    if @user.cloud_access_choice
      case @user.cloud_access_choice.to_i
      when CloudAccess::FLEX
        action = 'confirm_flex'
        @product = 'flex'
      when CloudAccess::EXPRESS
        action = 'confirm_express'
        @product = 'express'
      end
    end
    flash[:product] = @product

    # Stop if you have a validation error
    unless valid
      respond_to do |format|
        format.js { render :json => @user.errors and return }
        format.html { render :new and return }
      end
    end

    confirmationUrl = url_for(:action => action,
                              :controller => 'email_confirm',
                              :only_path => false,
                              :protocol => 'https')

    @user.register(confirmationUrl)

    unless @user.errors.length == 0
      respond_to do |format|
        format.js { render :json => @user.errors and return }
        format.html { render :new and return }
      end
    end
    
    # Successful user registration event for analytics
    @event = 'event29'
    
    # Redirect to a running workflow if it exists
    respond_to do |format|
      format.js { render :json => {:redirectUrl => user_complete_path } }
      format.html { workflow_redirect }
    end
  end

  def complete
    @event = 'event29' # set omniture 'simple registration' event
    @product = flash[:product] #set product for 'simple registration' event
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
    Rails.logger.debug "External registration request"

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

  def reset_password
    Rails.logger.debug params.to_yaml

    # Keep track of response information
    responseText = {
      :status => 'success',
      :message => "The information you have requested has been emailed to you at #{params[:email]}."
    }

    # Test the email against the WebUser validations
    user = WebUser.new({:email_address => params[:email]})
    user.valid?
    errors =  user.errors[:email_address]

    # Return if there is a problem with the email address
    unless errors.empty?
      responseText[:status] = 'error'
      responseText[:message] = 'The email supplied is invalid'

      respond_to do |format|
        format.js { render :json => responseText and return }
      end
    end


    unless Rails.configuration.integrated
      Rails.logger.warn "Non integrated environment - faking password reset"
    else
      uri = URI.join( Rails.configuration.streamline[:host], Rails.configuration.streamline[:lost_password_url])
      
      # Create the HTTPS object
      https = Net::HTTP.new( uri.host, uri.port )
      Rails.logger.debug "Integrated login, use SSL"
      if uri.scheme == 'https'
        https.use_ssl = true
        # TODO: Need to figure out where CAs are so we can do something like:
        #   http://goo.gl/QLFFC
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
          
      # Make the request
      req = Net::HTTP::Post.new( uri.path )
      req.set_form_data({ :login => params[:email] })
  
      # Create the request
      # Add timing code
      start_time = Time.now
      res = https.start{ |http| http.request(req) }
      end_time = Time.now
      Rails.logger.debug "Response from Streamline took (#{uri.path}): #{(end_time - start_time)*1000} ms"
  
      Rails.logger.debug res.code
      Rails.logger.debug "#{res.body.to_yaml}"

      case res
      when Net::HTTPSuccess
        # Assume any successful POST is valid to prevent against username enumeration
      else
        responseText[:status] = 'error'
        responseText[:message] = 'An unknown error occurred, please try again'
      end
    end

    respond_to do |format|
      format.js { render :json => responseText }
    end
  end

  def change_password
    user = session_user

    responseText = {
      :status => 'success',
      :message => "Your password has been successfully changed"
    }

    json = user.change_password({
      'oldPassword' => params['old_password'],
      'newPassword' => params['password'],
      'newPasswordConfirmation' => params['password_confirmation']
    })

    Rails.logger.debug "---------------"
    Rails.logger.debug "  change_pass  "
    Rails.logger.debug "---------------"
    Rails.logger.debug json.to_yaml
    Rails.logger.debug "---------------"

    if json['errors']
      responseText[:status] = 'error'
      Rails.logger.debug "Errors"
      if json['errors'].include? 'password_invalid'
        responseText[:message] = "Please choose a valid new password"
      elsif json['errors'].include? 'password_incorrect'
        responseText[:message] = "Your old password was incorrect"
      end
    end

    respond_to do |format|
      format.js { render :json => responseText }
    end
  end
end
