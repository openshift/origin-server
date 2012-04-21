class UserController < BaseController
  respond_to :json, :xml
  before_filter :authenticate, :check_version
  
  # GET /user
  def show
    if(@cloud_user.nil?)
      @reply = RestReply.new(:not_found)
      @reply.messages.push(Message.new(:error, "User #{@login} not found", 99))
      respond_with @reply, :status => @reply.status
      return
    end
    
    @reply = RestReply.new(:ok, "user", RestUser.new(@cloud_user, get_url))
    respond_with @reply, :status => @reply.status
  end
end
