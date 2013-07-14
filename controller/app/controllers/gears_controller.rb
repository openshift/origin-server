class GearsController < BaseController

  def show
    url = request.url
    new_url = url[0..url.rindex("/")] << "gear_groups"
    render_error(:moved_permanently, "Please use this URL instead #{new_url}", 112)
  end

  def index
    url = request.url
    new_url = url[0..url.rindex("/")] << "gear_groups"
    render_error(:moved_permanently, "Please use this URL instead #{new_url}", 112)
  end
end
