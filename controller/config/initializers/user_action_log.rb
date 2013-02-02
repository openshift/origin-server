if Rails.configuration.user_action_logging[:logging_enabled]
  if file = Rails.configuration.user_action_logging[:log_filepath]
    OpenShift::UserActionLog.logger = Logger.new(file)
  end
end

