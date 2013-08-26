require_dependency "admin_console/application_controller"

module AdminConsole
  class SuggestionsController < ApplicationController
    def index
      reload = params[:reload]
      @stats = AdminConsole::Stats.systems_summaries(reload)
      @stats_created_at = @stats.created_at
      @suggestions = @stats.suggestions
      if Rails.env.development? && n = params[:tsugs]
        @suggestions = Admin::Suggestion::Advisor.subclass_test_instances.
                       slice(0, n.to_i).compact
      end
      @config = Rails.application.config.admin_console

      @expanded = params[:expanded]
    end
  end
end
