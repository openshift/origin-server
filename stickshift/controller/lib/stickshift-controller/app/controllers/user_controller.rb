class UserController < BaseController
  respond_to :json, :xml
  before_filter :authenticate, :check_version
  
  # GET /user
  def show
    if(@cloud_user.nil?)
      log_action(@request_id, 'nil', @login, "SHOW_USER", false, "User '#{@login}' not found")
      @reply = RestReply.new(:not_found)
      @reply.messages.push(Message.new(:error, "User not found", 99))
      respond_with @reply, :status => @reply.status
      return
    end
    
    log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "SHOW_USER")
    @reply = RestReply.new(:ok, "user", RestUser.new(@cloud_user, get_url))
    respond_with @reply, :status => @reply.status
  end
end
