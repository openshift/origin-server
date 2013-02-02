class BaseController < ActionController::Base
  before_filter :check_nolinks
  before_filter :check_version
  include OpenShift::Controller::ActionLog
  include OpenShift::Controller::Authentication
  include OpenShift::Controller::ApiResponses
  include OpenShift::Controller::ApiBehavior
  #Mongoid.logger.level = Logger::WARN
  #Moped.logger.level = Logger::WARN

  # Initialize domain/app variables to be used for logging in user_action.log
  # The values will be set in the controllers handling the requests
  @domain_name = nil
  @application_name = nil
  @application_uuid = nil

  before_filter :set_locale
end
