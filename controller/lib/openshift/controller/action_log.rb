module OpenShift::Controller::ActionLog
  extend ActiveSupport::Concern

  included do
    around_filter :set_logged_request
  end

  module ClassMethods
    #
    # Override the default controller log resource by calling:
    #
    #   action_log_tag_resource :name_with_underscore
    #
    def action_log_tag_resource(resource)
      s = resource.to_s.upcase
      define_method :action_log_tag_resource do
        s
      end
    end
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

    #
    # The tag for an action made from this controller method
    #
    def action_log_tag_action
      case request.method
      when "GET"    then params[:id] ? "SHOW" : "LIST"
      when "POST"   then "ADD" 
      when "PUT"    then "UPDATE"
      when "DELETE" then "DELETE"
      else               "UNKNOWN"
      end
    end

    #
    # The resource that is being logged
    #
    def action_log_tag_resource
      controller_name.singularize.upcase
    end

    #
    # The user action log tag for requests made from this controller.
    #
    def action_log_tag
      @action_log_tag ||= "#{action_log_tag_action}_#{action_log_tag_resource}"
    end
    #
    # Override the action log tag for a particular action.  Should be set
    # as early as possible in the request chain.
    #
    attr_writer :action_log_tag

  private
    def set_logged_request
      OpenShift::UserActionLog.begin_request(request)
      yield
    ensure
      OpenShift::UserActionLog.end_request
    end
end
