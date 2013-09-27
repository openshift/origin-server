class UserController < BaseController
  include RestModelHelper

  # GET /user
  def show
    return render_error(:not_found, "User '#{@login}' not found", 99) unless @cloud_user
    render_success(:ok, "user", get_rest_user(@cloud_user))
  end

  # DELETE /user
  # NOTE: Only applicable for subaccount users
  def destroy
    force = get_bool(params[:force])

    return render_error(:not_found, "User '#{@login}' not found", 99) unless @cloud_user
    return render_error(:forbidden, "User deletion not permitted. Only applicable for subaccount users.", 138) unless @cloud_user.parent_user_id

    authorize! :destroy, current_user

    if force
      result = @cloud_user.force_delete
    else
      return render_error(:unprocessable_entity, "User '#{@cloud_user.login}' has valid domains. Either delete domains and retry the operation or use 'force' option.", 139) if @cloud_user.domains.present?
      result = @cloud_user.delete
    end
    status = requested_api_version <= 1.4 ? :no_content : :ok
    render_success(status, nil, nil, "User #{@cloud_user.login} deleted.", result)
  end
end
