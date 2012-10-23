class AccountController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  
  def create
    username = params[:username]
    password = params[:password]
    
    auth_config = Rails.application.config.auth
    auth_service = OpenShift::MongoAuthService.new(auth_config)
    
    Rails.logger.debug "username = #{username}, password = #{password}"
    
    if(username.nil? || password.nil? || username.strip.empty? || password.strip.empty?)
      log_action('nil', 'nil', username, "ADD_USER", false, "Username or password not specified or empty")
      @reply = RestReply.new(:unprocessable_entity)
      @reply.messages.push(Message.new(:error, "Invalid username or password", 1001, "username"))
      respond_with @reply, :status => @reply.status
      return
    end
    
    if auth_service.user_exists?(username)
      log_action('nil', 'nil', username, "ADD_USER", false, "User '#{username}' already registered")
      @reply = RestReply.new(:unprocessable_entity)
      @reply.messages.push(Message.new(:error, "Error: User '#{username}' already registered.", 1002, "id"))
      respond_with @reply, :status => @reply.status
    else
      log_action('nil', 'nil', username, "ADD_USER", true, "User '#{username}' successfully registered")
      auth_service.register_user(username,password)
      @reply = RestReply.new(:created, "domain", RestAccount.new(username, Time.new))
      respond_with @reply, :status => @reply.status
    end
  end
end
