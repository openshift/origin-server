class AccountController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  
  def create
    username = params[:username]
    password = params[:password]
    
    auth_config = Rails.application.config.auth
    auth_service = OpenShift::MongoAuthService.new(auth_config)
    
    Rails.logger.debug "username = #{username}, password = #{password}"
    
    return render_error(:unprocessable_entity, "Invalid username or password", 1001, "ADD_AUTH_USER", "username") if username.to_s.strip.empty? || password.to_s.strip.empty?
    return render_error(:unprocessable_entity, "Error: User '#{username}' already registered.", 1002, "ADD_AUTH_USER", "id") if auth_service.user_exists?(username)
    
    auth_service.register_user(username, password)
    render_success(:created, "account", RestAccount.new(username, Time.new), "ADD_AUTH_USER", "User '#{username}' successfully registered")
  end
end
