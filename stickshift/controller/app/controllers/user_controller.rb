class UserController < BaseController
  respond_to :json, :xml
  before_filter :authenticate, :check_version
  
  # GET /user
  def show
    return render_error(:not_found, "User '#{@login}' not found", 99, "SHOW_USER") unless @cloud_user
    render_success(:ok, "user", RestUser.new(@cloud_user, get_url, nolinks), "SHOW_USER")
  end
end
