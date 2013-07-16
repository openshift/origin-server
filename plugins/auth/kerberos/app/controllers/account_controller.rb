class AccountController < BaseController

  def create
    username = params[:username]
    Rails.logger.debug "username = #{username}"
    return render_error(:unprocessable_entity, "Cannot create account, managed by kerberos", 1001, "username")
  end
end
