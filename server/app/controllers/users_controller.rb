require 'pp'
require 'net/http'
require 'net/https'
require 'recaptcha'
require 'json'

class UsersController < ApplicationController

  def index
    @user = WebUser.new
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
      pp @user.errors
    end unless Rails.env == "development"

    # Stop if you have a validation error
    render :index and return unless valid

    confirmationUrl = url_for(:action => 'confirm',
                              :controller => 'email_confirm',
                              :only_path => false,
                              :protocol => 'https')

    @user.register(confirmationUrl)

    # Redirect to a running workflow if it exists
    redirect_to session[:workflow] if session[:workflow]
  end
end
