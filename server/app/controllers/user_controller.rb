require 'pp'
require 'net/http'
require 'net/https'
require 'recaptcha'
require 'json'

class UserController < ApplicationController

  def new(cloud_access_choice=nil)
    @user = WebUser.new({:cloud_access_choice => cloud_access_choice})
    render :new and return
  end
  
  def new_flex
    new(CloudAccess::FLEX)
  end
  
  def new_express
    new(CloudAccess::EXPRESS)
  end

  def create
    @user = WebUser.new(params[:web_user])

    # TODO - Remove
    # Only applicable for the beta registration process
    @user.terms_accepted = '1'

    # Run validations
    valid = @user.valid?

    # Verify the captcha
    unless verify_recaptcha
      valid = false
      @user.errors[:captcha] = "Captcha text didn't match"
    end unless Rails.env == "development"

    # Stop if you have a validation error
    render :new and return unless valid

    action = 'confirm'
    if @user.cloud_access_choice
      case @user.cloud_access_choice.to_i
      when CloudAccess::EXPRESS
        action = 'confirm_express'
      when CloudAccess::FLEX
        action = 'confirm_flex'
      end
    end

    confirmationUrl = url_for(:action => action,
                              :controller => 'email_confirm',
                              :only_path => false,
                              :protocol => 'https')

    @user.register(confirmationUrl)
    
    render :new and return unless @user.errors.length == 0

    # Redirect to a running workflow if it exists
    redirect_to session[:workflow] if session[:workflow]
  end
end
