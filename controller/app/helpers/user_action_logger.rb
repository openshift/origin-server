module UserActionLogger

  @@action_logger = nil
  
  def get_action_logger()
    unless @@action_logger
      log_file = nil
      if Rails.configuration.user_action_logging[:logging_enabled]
        log_file = Rails.configuration.user_action_logging[:log_filepath]
      end
      @@action_logger = Logger.new(log_file) unless log_file.nil?
    end
    @@action_logger
  end
  
  def log_action(request_id, user_id, login, action, success = true, description = "", args = {})
    log_level = success ? Logger::DEBUG : Logger::ERROR
    action_logger = get_action_logger()

    if not action_logger.nil?
      result = success ? "SUCCESS" : "FAILURE"
      time_obj = Time.new
      date = time_obj.strftime("%Y-%m-%d")
      time = time_obj.strftime("%H:%M:%S")
      
      message = "#{result} DATE=#{date} TIME=#{time} ACTION=#{action} REQ_ID=#{request_id} USER_ID=#{user_id} LOGIN=#{login}"
      args.each {|k,v| message += " #{k}=#{v}"}
      
      action_logger.info("#{message} #{description}")
    end
    
    # Using a block prevents the message in the block from being executed 
    # if the log_level is lower than the one set for the logger
    Rails.logger.add(log_level) {"[REQ_ID=#{request_id}] ACTION=#{action} #{description}"}
  end

end
