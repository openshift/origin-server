require_dependency "admin_console/application_controller"

module AdminConsole
  class IndexController < ApplicationController
    def index
      reload = params[:reload]
      stats = AdminConsole::Stats.systems_summaries(reload)
      @summary_for_profile = stats.profile_summaries_hash
      @stats_created_at = stats.created_at
      @suggestions = stats.suggestions
      @config = Rails.application.config.admin_console
    end
  end
end
