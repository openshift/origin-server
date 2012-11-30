class UserController < BaseController
  respond_to :json, :xml
  before_filter :authenticate, :check_version
  
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
  
    if force
      @cloud_user.domains.each do |domain|
        domain.applications.each do |app|
          app.destroy_app
        end if domain.applications.count > 0
        domain.delete
      end if @cloud_user.domains.count > 0
    elsif @cloud_user.domains.count > 0
      return render_error(:unprocessable_entity, "User '#{@login}' has valid domains. Either delete domains and retry the operation or use 'force' option.", 139, "DELETE_USER")
    end
  
    begin
      @cloud_user.delete
      render_success(:no_content, nil, nil, "DELETE_USER", "User #{@login} deleted.", true)
    rescue Exception => e
      return render_exception(e, "DELETE_USER")
    end
  end

  private

  def get_rest_user(cloud_user)
    if $requested_api_version >= 1.3
      RestUser13.new(cloud_user, get_url, nolinks)
    else
      RestUser10.new(cloud_user, get_url, nolinks)
    end
  end
end
