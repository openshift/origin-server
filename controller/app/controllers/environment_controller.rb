class EnvironmentController < BaseController

  skip_before_filter :authenticate_user!

  # URL: /environment
  #
  # Action: GET
  def show
    environment = {}
    environment['domain_suffix'] = Rails.application.config.openshift[:domain_suffix] 
    environment['download_cartridges_enabled'] = Rails.application.config.openshift[:download_cartridges_enabled]
    render_success(:ok, "environment", environment, "Showing broker environment")
  end
end
