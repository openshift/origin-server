class AccountController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  
  def create
    username = params[:username]
    password = params[:password]
    
    auth_config = Rails.application.config.auth
    auth_service = Swingshift::MongoAuthService.new(auth_config)
    
    Rails.logger.debug "username = #{username}, password = #{password}"
    
    if(username.nil? || password.nil? || username.strip.empty? || password.strip.empty?)
      @reply = RestReply.new(:unprocessable_entity)
      @reply.messages.push(Message.new(:error, "Invalid username or password", 1001, "username"))
      respond_with @reply, :status => @reply.status
      return
    end
    
    if auth_service.user_exists?(username)
      @reply = RestReply.new(:unprocessable_entity)
      @reply.messages.push(Message.new(:error, "Error: User '#{username}' already registered.", 1002, "id"))
      respond_with @reply, :status => @reply.status
    else
      auth_service.register_user(username,password)
      @reply = RestReply.new(:created, "domain", RestAccount.new(username, Time.new))
      respond_with @reply, :status => @reply.status
    end
  end
end