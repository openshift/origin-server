module AdminConsole
  class Stats
    def self.collect
      {
        :application => {
          :total => Application.count
        },
        :user => {
          :total => CloudUser.count
        },
        :domain => {
          :total => Domain.count
        }
        #TODO node
      }
    end

    # in the case where we get Admin:: classes from the cache before
    # they have actually been defined... ensure their namespaces load.
    require 'admin/stats'
    require 'admin/suggestion/advisor'

    def self.systems_summaries(force_reload = false, conf = Rails.application.config.admin_console)
      Rails.cache.fetch('admin_console_system_statistics',
                        expires_in: conf[:stats][:cache_timeout],
                        force: force_reload) do
        gather_systems_statistics(conf)
      end
    end

    protected

    # Create system stats via Admin::Stats according to conf.
    # Also generate Admin::Suggestions with 'suggestions' key.
    # Time of generation/loading is stored in 'created_at' key.
    def self.gather_systems_statistics(config = {})
      # gather the stats as requested
      stats_conf = config[:stats] || {}
      stats = Admin::Stats.new wait: stats_conf[:mco_timeout],
                          read_file: stats_conf[:read_file] ||config[:debug_profile_data]
      stats.gather_statistics
      results = stats.results
      # generate suggestions based on the stats and bundle into results hash.
      suggestions = Admin::Suggestion::Advisor.query(config[:suggest], results)
      results.merge 'created_at' => Time.now, 'suggestions' => suggestions
    end

  end
end
