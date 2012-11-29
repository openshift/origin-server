class UserController < BaseController
  respond_to :json, :xml
  before_filter :authenticate, :check_version
  
  # GET /user
  def show
    unless @cloud_user
      log_action(@request_id, 'nil', @login, "SHOW_USER", true, "User '#{@login}' not found")
      return render_error(:not_found, "User '#{@login}' not found", 99)
    end
    render_success(:ok, "user", RestUser.new(@cloud_user, get_url, nolinks), "SHOW_USER")
  end

  # DELETE /user
  # NOTE: Only applicable for subaccount users
  def destroy
    force = get_bool(params[:force])
  
    unless @cloud_user
      log_action(@request_id, 'nil', @login, "DELETE_USER", true, "User '#{@login}' not found")
      return render_format_error(:not_found, "User '#{@login}' not found", 99)
    end
    return render_format_error(:forbidden, "User deletion not permitted. Only applicable for subaccount users.", 138, "DELETE_USER") unless @cloud_user.parent_user_login
  
    begin
      if force
        @cloud_user.force_delete
      else
        return render_format_error(:unprocessable_entity, "User '#{@login}' has valid domain or applications. Either delete domain, applications and retry the operation or use 'force' option.",
                                   139, "DELETE_USER") if !@cloud_user.domains.empty? or !@cloud_user.applications.empty?
        @cloud_user.delete
      end
      render_format_success(:no_content, nil, nil, "DELETE_USER", "User #{@login} deleted.", true)
    rescue Exception => e
      return render_format_exception(e, "DELETE_USER")
    end
  end
end
