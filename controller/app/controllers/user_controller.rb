class UserController < BaseController

  # GET /user
  def show
    return render_error(:not_found, "User '#{@login}' not found", 99, "SHOW_USER") unless @cloud_user
    render_success(:ok, "user", get_rest_user(@cloud_user), "SHOW_USER")
  end

  # DELETE /user
  # NOTE: Only applicable for subaccount users
  def destroy
    force = get_bool(params[:force])

    return render_error(:not_found, "User '#{@login}' not found", 99, "DELETE_USER") unless @cloud_user
    return render_error(:forbidden, "User deletion not permitted. Only applicable for subaccount users.", 138, "DELETE_USER") unless @cloud_user.parent_user_id

    begin
      if force
        @cloud_user.force_delete
      else
        return render_error(:unprocessable_entity, "User '#{@cloud_user.login}' has valid domains. Either delete domains and retry the operation or use 'force' option.", 139, "DELETE_USER") if @cloud_user.domains.count > 0
        @cloud_user.delete
      end
      render_success(:no_content, nil, nil, "DELETE_USER", "User #{@cloud_user.login} deleted.", true)
    rescue Exception => e
      return render_exception(e, "DELETE_USER")
    end
  end

  private

    def get_rest_user(cloud_user)
      if requested_api_version == 1.0
        RestUser10.new(cloud_user, get_url, nolinks)
      else
        RestUser.new(cloud_user, get_url, nolinks)
      end
    end
end
