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

      @suggestions.sort! { |x, y| sort_suggestions(x, y)}

      @config = Rails.application.config.admin_console

      @expanded = params[:expanded]
    end

    protected

    def sort_suggestions(x, y)
      case
      when x.important? && y.important?
        xklass = x.is_a?(Class) ? x : x.class
        yklass = y.is_a?(Class) ? x : y.class
        xklass.to_s <=> yklass.to_s
      when x.important? && !y.important?
        -1
      when !x.important? && y.important
        1
      else
        xklass = x.is_a?(Class) ? x : x.class
        yklass = y.is_a?(Class) ? x : y.class
        xklass.to_s <=> yklass.to_s
      end       
    end
  end
end
