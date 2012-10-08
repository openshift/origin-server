class AccountController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version

  def create
    username = params[:username]

    auth_config = Rails.application.config.auth
    auth_service = OpenShift::KerberosAuthService.new(auth_config)

    Rails.logger.debug "username = #{username}"

    log_action('nil', 'nil', username, "ADD_USER", false, "Cannot create account, managed by kerberos")
    @reply = RestReply.new(:unprocessable_entity)
    @reply.messages.push(Message.new(:error, "Cannot create account, managed by kerberos", 1001, "username"))
    respond_with @reply, :status => @reply.status
    return

  end
end
