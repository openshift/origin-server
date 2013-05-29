class BaseController < ActionController::Base
  include OpenShift::Controller::ActionLog
  include OpenShift::Controller::Authentication
  include OpenShift::Controller::ScopeAuthorization
  include OpenShift::Controller::ApiResponses
  include OpenShift::Controller::ApiBehavior

  before_filter :set_locale,
                :check_nolinks,
                :check_version,
                :check_outage,
                :authenticate_user!,
                :set_log_tag

  def render_upgrade_in_progress
    return render_error(:unprocessable_entity, "Your application is being upgraded and configuration changes can not be made at this time.  Please try again later.", 1)
  end
end
