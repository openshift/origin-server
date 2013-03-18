class BaseController < ActionController::Base
  include OpenShift::Controller::ActionLog
  include OpenShift::Controller::Authentication
  include OpenShift::Controller::ScopeAuthorization
  include OpenShift::Controller::ApiResponses
  include OpenShift::Controller::ApiBehavior

  before_filter :set_locale,
                :check_outage,
                :check_nolinks,
                :check_version,
                :authenticate_user!,
                :set_log_tag
end
