class BaseController < ActionController::Base
  include OpenShift::Controller::ActionLog
  include OpenShift::Controller::Authentication
  include OpenShift::Controller::ApiResponses
  include OpenShift::Controller::ApiBehavior

  protect_from_forgery

  before_filter :set_locale,
                :check_nolinks,
                :check_version,
                :authenticate

  protected

	def has_unguessable_auth?
	  request.cookies[Rails.configuration.auth_cookie_name].nil?
	end

	def verified_request?
	  !protect_against_forgery? || has_unguessable_auth? ||
	  form_authenticity_token == params[request_forgery_protection_token] ||
	  form_authenticity_token == request.headers['X-CSRF-Token'] ||
	  !Rails.configuration.auth[:integrated]
	end

	def handle_unverified_request
	  Rails.logger.error "Failed CSRF token check"
	  reset_session
	  request_http_basic_authentication
	end

end
