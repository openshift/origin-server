class UserController < BaseController
  respond_to :json, :xml
  before_filter :authenticate, :check_version
  
  # GET /user
  def show
    unless @cloud_user
      log_action(@request_id, 'nil', @login, "SHOW_USER", false, "User '#{@login}' not found")
      return render_error(:not_found, "User '#{@login}' not found", 99)
    end
    render_success(:ok, "user", RestUser.new(@cloud_user, get_url, nolinks), "SHOW_USER")
  end
end
