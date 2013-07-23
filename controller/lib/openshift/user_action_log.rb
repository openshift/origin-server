module OpenShift::UserActionLog

  def self.begin_request(request)
    Thread.current[:user_action_log_uuid] = request ? request.uuid : nil
  end
  def self.end_request
    # Does not reset vars so that rescue_from handlers have access to the current log context
  end
  def self.with_user(id, login)
    Thread.current[:user_action_log_user_id] = id
    Thread.current[:user_action_log_identity_id] = login
  end

  def self.action(action, success=true, description=nil, args={}, detailed_description=nil)
    return unless logger

    result = success ? "SUCCESS" : "FAILURE"
    description = (description || "").strip
    detailed_description = (detailed_description || "").strip
    time_obj = Time.new
    date = time_obj.strftime("%Y-%m-%d")
    time = time_obj.strftime("%H:%M:%S")

    message = "#{result} DATE=#{date} TIME=#{time} ACTION=#{action} REQ_ID=#{Thread.current[:user_action_log_uuid]}"
    auth = " USER_ID=#{Thread.current[:user_action_log_user_id]} LOGIN=#{Thread.current[:user_action_log_identity_id]}"
    extra = args.map{|k,v| " #{k}=#{v}"}.join

    # We are not logging the detailed multi-line logs in the user action logger 
    logger.info("#{message}#{auth}#{extra} #{description}")

    unless Rails.env.production?
      # Using a block prevents the message in the block from being executed 
      # if the log_level is lower than the one set for the logger
      Rails.logger.add(Logger::DEBUG){ "  #{result} ACTION=#{action}#{auth}#{extra} #{description} #{detailed_description}" }
    end
  end

  class << self
    attr_writer :logger
    private
      attr_reader :logger
  end
end
