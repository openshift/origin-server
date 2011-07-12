require 'pp'
require 'net/http'
require 'net/https'
require 'recaptcha'
require 'json'

class UserController < ApplicationController

  def new(cloud_access_choice=nil)
    @product = 'openshift' unless defined? @product
    @user = WebUser.new({:cloud_access_choice => cloud_access_choice})
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

    # Stop if you have a validation error
    render :new and return unless valid

    confirmationUrl = url_for(:action => action,
                              :controller => 'email_confirm',
                              :only_path => false,
                              :protocol => 'https')

    @user.register(confirmationUrl)

    render :new and return unless @user.errors.length == 0
    
    # Successful user registration event for analytics
    @event = 'event29'
    
    # Redirect to a running workflow if it exists
    workflow_redirect    
  end
end
