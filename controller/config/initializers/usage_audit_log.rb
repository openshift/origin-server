if Rails.configuration.usage_tracking[:audit_log_enabled]
  logger = nil

  if Rails.configuration.openshift[:syslog_enabled]
    logger = OpenShift::Syslog.logger_for('openshift-broker', 'usage')
  elsif file = Rails.configuration.usage_tracking[:audit_log_filepath]
    logger = Logger.new(file)

    logger.formatter = proc do |severity, datetime, progname, msg|
      "#{datetime}:: #{msg}\n"
    end
  end

  OpenShift::UsageAuditLog.logger = logger if logger
end
