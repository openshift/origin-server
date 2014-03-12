class QuickstartsController < BaseController
  clear_respond_to
  respond_to :json

  skip_before_filter :authenticate_user!

  def index
    render_success(:ok, "quickstarts", quickstarts, "Showing all quickstarts")
  end

  def show
    id = params[:id].presence
    if quickstart = quickstarts.find{ |obj| obj['quickstart']['id'] == id }
      render_success(:ok, "quickstarts", [quickstart],  "Showing quickstart for '#{id}'")
    else
      render_error(:not_found, "Quickstart '#{id}' not found", 118)
    end
  end

  protected
    def quickstarts
      if File.exists?(file)
        begin
          ActiveSupport::JSON.decode(IO.read(file))
        rescue Exception => e
          Rails.logger.error "Failed to load #{file}: #{e.message}"
          []
        end
      else
        Rails.logger.warn "#{file} not found!"
        []
      end
    end

    def file
      File.join(OpenShift::Config::CONF_DIR, 'quickstarts.json')
    end
end
