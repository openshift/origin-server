module AdminConsole
  class IndexController < ApplicationController
    def index
      @stats = AdminConsole::Stats.systems_summaries
      @stats_created_at = @stats.created_at
      @suggestions = @stats.suggestions
      if (!Rails.env.production?) && n = params[:tsugs]
        @suggestions = Admin::Suggestion::Advisor.subclass_test_instances.
                       slice(0, n.to_i).compact
      end
      @suggestions.sort_by!{ |s| [s.important? ? 0 : 1, s.is_a?(Class) ? s.to_s : s.class.to_s] }

      @config = Rails.application.config.admin_console
      @cache_timeout = @config[:stats][:cache_timeout]
      @active_warning_threshold = @config[:warn][:node_active_remaining]

      @summary_for_profile = @stats.profile_summaries_hash
    end

    def reload
      AdminConsole::Stats.clear
      redirect_to params[:then] || admin_console_path
    end
  end
end
