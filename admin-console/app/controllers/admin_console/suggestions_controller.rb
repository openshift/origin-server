require_dependency "admin_console/application_controller"

module AdminConsole
  class SuggestionsController < ApplicationController
    def index
      @suggestions = AdminConsole::Stats.systems_summaries.suggestions
      @config = Rails.application.config.admin_console
      @expanded = params[:expanded]
    end
  end
end
