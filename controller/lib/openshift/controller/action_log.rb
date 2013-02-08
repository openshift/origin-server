module OpenShift::Controller::ActionLog
  extend ActiveSupport::Concern

  included do
    around_filter :set_logged_request
  end

  protected
    #
    # Log an action for a user who has not been authenticated yet.
    # Will override any previous call to log_actions_as.
    #
    def log_action_for(login, user_id, *arguments)
      OpenShift::UserActionLog.with_user(user_id, login)
      OpenShift::UserActionLog.action(*arguments)
    end
    #
    # Log an action for the current user
    #
    def log_action(*arguments)
      OpenShift::UserActionLog.action(*arguments)
    end

    #
    # Log subsequent actions as the given user
    #
    def log_actions_as(user)
      OpenShift::UserActionLog.with_user(user.id, user.login)
    end

  private
    def set_logged_request
      OpenShift::UserActionLog.begin_request(request)
      yield
    ensure
      OpenShift::UserActionLog.end_request
    end
end
