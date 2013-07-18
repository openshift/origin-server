require_dependency "admin_console/application_controller"

module AdminConsole
  class StatsController < ApplicationController
    respond_to :json

    def index
      @stats = AdminConsole::Stats.collect
    end

    # rest api that collects the advanced, long-running statistics
    def show
      case params[:id]
      when "gears_per_user"
        respond_with CloudUserStats.gears_per_user_binning
      when "apps_per_domain"
        respond_with ApplicationStats.apps_per_domain_binning
      else
        #TODO respond with 404
      end
    end
  end
end
