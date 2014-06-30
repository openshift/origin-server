class RegionsController < BaseController
  include RestModelHelper
  skip_before_filter :authenticate_user!

  def show
    id = params[:id].presence
    region = Region.find(id)
    render_success(:ok, "region", RestRegion.new(region), "Showing region #{id}")
  end
  def index
    regions = Region.where({}).map{|r| RestRegion.new(r)}
    render_success(:ok, "regions", regions, "Listing #{regions.length} region(s)")
  end
end
