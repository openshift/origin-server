module OpenShift::UsageAuditLog

  def self.is_enabled?
    (logger ? true : false)
  end

  def self.log(message)
    return unless logger
    logger.info message
  end

  class << self
    attr_writer :logger
    private
      attr_reader :logger
  end
end
