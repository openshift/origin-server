if Rails.configuration.usage_tracking[:audit_log_enabled]
  if file = Rails.configuration.usage_tracking[:audit_log_filepath]
    logger = Logger.new(file)
    logger.formatter = proc do |severity, datetime, progname, msg|
      "#{datetime}:: #{msg}\n"
    end
    OpenShift::UsageAuditLog.logger = logger
  end
end
