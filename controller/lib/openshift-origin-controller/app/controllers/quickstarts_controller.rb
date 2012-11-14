class QuickstartsController < BaseController
  respond_to :json
  before_filter :check_version

  def index
    render_success(:ok, "quickstarts", quickstarts, "LIST_QUICKSTARTS", "Showing all quickstarts")
  end

  def show
    id = params[:id]
    if quickstart = quickstarts.find{ |obj| obj['quickstart']['id'] == id }
      render_success(:ok, "quickstarts", [quickstart], "SHOW_QUICKSTART",  "Showing quickstart for '#{id}'")
    else
      render_error(:not_found, "Quickstart '#{id}' not found", 118, "SHOW_QUICKSTART")
    end
  end

  protected
    def quickstarts
      if File.exists?(file)
        ActiveSupport::JSON.decode(IO.read(file)) rescue []
      else
        []
      end
    end
    def file
      File.join(OpenShift::Config::CONF_DIR, 'quickstarts.json')
    end
end
