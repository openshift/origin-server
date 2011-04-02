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
            'terms_not_accepted' => 'Terms must be accepted',
            :unknown => 'An unknown error has occurred'
  }

  def index
    @user = ::User.new
  end

  def create
    @user = ::User.new(params[:user])

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
      url = URI.parse(Rails.configuration.corp_server + '/registration.html')
      req = Net::HTTP::Post.new(url.path)

      req.set_form_data({ 'emailAddress' => @user.emailAddress,
                          'password' => @user.password,
                          'passwordConfirmation' => @user.passwordConfirmation,
                          'secretKey' => 'c0ldW1n3',
                          'termsAccepted' => 'true',
                          'confirmationUrl' => url_for(:action => 'confirm',
                                                   :controller => 'email_confirm',
                                                   :only_path => false,
                                                   :protocol => 'https')
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
        logger.debug "Response body: #{response.body}"

        begin
          result = JSON.parse(response.body)
          if (result['errors'])
            errors = result['errors']
            errors.each { |error|
              if (ERRORS[error])
                @user.errors[error] = ERRORS[error]
              else
                @user.errors[:unknown] = ERRORS[:unknown]
              end
            }
          elsif result['emailAddress']
            #success
          else
            @user.errors[:unknown] = ERRORS[:unknown]
          end
        rescue Exception => e
          logger.error e
          @user.errors[:unknown] = ERRORS[:unknown]
        end
      else
        logger.error "Problem with server. Response code was #{response.code}"
        logger.error "HTTP response from server is #{response.body}"
        @user.errors[:unknown] = ERRORS[:unknown]
      end

    rescue Exception => e
      logger.error e
      @user.errors[:unknown] = ERRORS[:unknown]
    ensure
      if (@user.errors.length > 0)
        render :index and return
      end
    end
  end
end
