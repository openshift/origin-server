require 'pp'
require 'net/http'
require 'net/https'
require 'recaptcha'
require 'json'

class UsersController < ApplicationController
  
  ERRORS = {'user_already_registered' => 'A user with the same email is already registered',
            'contact_customer_service' => 'Please contact customer service.  This login has attempted to register more than five times without verifying his or her email address.',            
            'email_required' => 'Email address is required',
            'email_invalid' => 'The given email address is not a valid email format',            
            'password_required' => 'Password is required',
            'password_match_failure' => 'Passwords must match',
            'terms_not_accepted' => 'Terms must be accepted'
  }
  
  def index
    @user = User.new
  end

  def create
    @user = User.new(params[:user])

    # TODO - Remove
    # Only applicable for the beta registration process
    @user.termsAccepted = '1'

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

    # Only register the user if in a non-development environment
    full_register unless Rails.env == "development"
  end

  # Call out to corporate service to register user
  # Map any errors into the user.errors object
  def full_register
    logger.debug 'Performing full registration'

    begin
      url = URI.parse('https://streamline.devlab.phx1.redhat.com/wapps/streamline/registration.html')
      req = Net::HTTP::Post.new(url.path)

      req.set_form_data({ 'emailAddress' => @user.emailAddress,
                          'password' => @user.password,
                          'passwordConfirmation' => @user.passwordConfirmation,
                          'secretKey' => 'c0ldW1n3',
                          'termsAccepted' => 'true',
                          'redirectUrl' => "http://li.beta.rhcloud.com/getting_started.html"
                          })
      http = Net::HTTP.new(url.host, url.port)
      if url.scheme == "https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      response = http.start {|http| http.request(req)}
      case response
      when Net::HTTPSuccess
        logger.debug "HTTP response from server is:"
        response.each do |k,v|
            logger.debug "#{k.to_s}: #{v.to_s}"
        end
        logger.debug "Response body: #{response.body}"
      else
        logger.debug "Problem with server. Response code was #{response.code}"
        logger.debug "HTTP response from server is #{response.body}"
        #reponse.body isn't really ideal yet just using assumed error for now
        errors = JSON.parse('["user_already_registered"]')
        #errors = JSON.parse(response.body)
        errors.each { |error|
          if (ERRORS[error])
            @user.errors[error] = ERRORS[error]
          else
            @user.errors[:unknown] = 'An unknown error has occurred' 
          end
          render :index and return
        }
      end

    rescue Net::HTTPBadResponse => e
      puts e
      raise
    end
  end
end
