class AccountController < BaseController

  def create
    username = params[:username]

    Rails.logger.debug "username = #{username}"

    log_action_for(username, nil, "ADD_USER", false, "Cannot create account, managed by kerberos")
    @reply = new_rest_reply(:unprocessable_entity)
    @reply.messages.push(Message.new(:error, "Cannot create account, managed by kerberos", 1001, "username"))
    respond_with @reply, :status => @reply.status
    return

  end
end
