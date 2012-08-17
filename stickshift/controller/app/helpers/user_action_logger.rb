module UserActionLogger
  @@action_logger = nil
  
  # Get the rails logger that logs REST API actions
  #
  # == Configuration parameters:
  # logging_enabled::
  #   Boolean indicating if action logs should be maintained
  # log_filepath::
  #   Path to action log
  #
  # == Returns:
  # Rails logger 
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
  
  # Logs REST API actions
  #
  # == Parameters:
  # request_id::
  #   ID to uniquely identify the request
  # user_id::
  #   ID of the {CloudUser} who requested this REST API operation
  # login::
  #   Login of the {CloudUser} who requested this REST API operation
  # action::
  #   [String] to identify the operation being performed
  # success::
  #   [Boolean] indicating if the operation was successful (Default: true)
  # description::
  #   [String] Long description of the operation being performed
  def log_action(request_id, user_id, login, action, success = true, description = "")
    log_level = success ? Logger::DEBUG : Logger::ERROR
    action_logger = get_action_logger()

    if not action_logger.nil?
      result = success ? "SUCCESS" : "FAILURE"
      time_obj = Time.new
      date = time_obj.strftime("%Y-%m-%d")
      time = time_obj.strftime("%H:%M:%S")
      action_logger.info("#{result} DATE=#{date} TIME=#{time} ACTION=#{action} REQ_ID=#{request_id} USER_ID=#{user_id} LOGIN=#{login} #{description}")
    end
    
    # Using a block prevents the message in the block from being executed 
    # if the log_level is lower than the one set for the logger
    Rails.logger.add(log_level) {"[REQ_ID=#{request_id}] ACTION=#{action} #{description}"}
  end

end
