if Rails.configuration.user_action_logging[:logging_enabled]
  if Rails.configuration.openshift[:syslog_enabled]
    OpenShift::UserActionLog.logger = OpenShift::Syslog.logger_for('openshift-broker', 'useraction')
  elsif file = Rails.configuration.user_action_logging[:log_filepath]
    OpenShift::UserActionLog.logger = Logger.new(file)
  end
end

