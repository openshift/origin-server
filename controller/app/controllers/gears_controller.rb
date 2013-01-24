class GearsController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  
  def show
    url = request.url
    new_url = url[0..url.rindex("/")] << "gear_groups"
    return render_error(:moved_permanently, "Please use this URL instead #{new_url}", 112, "LIST_GEARS")
  end
  def index
    url = request.url
    new_url = url[0..url.rindex("/")] << "gear_groups"
    return render_error(:moved_permanently, "Please use this URL instead #{new_url}", 112, "LIST_GEARS")
  end
end
