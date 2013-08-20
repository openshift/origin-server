module AdminConsole
  class Stats
    def self.collect
      {
        :application => {
          :total => Application.count
        },
        :user => {
          :total => CloudUser.count
        }
        #TODO node
      }
    end

    def self.systems_summaries(force_reload = false)
      Rails.cache.fetch('admin_console_system_statistics', :expires_in => Rails.application.config.admin_console[:node_data_cache_timeout], :force => force_reload) do
        gather_systems_statistics
      end
    end

    protected

    def self.gather_systems_statistics
      stats = Admin::Stats.new
      stats.gather_statistics
      results = stats.results.except(:node_entries, :district_entries, :district_summaries, :profile_summaries)
      # remove hashes with default blocks so we can cache them
      # See: http://stackoverflow.com/questions/6391855/rails-cache-error-in-rails-3-1-typeerror-cant-dump-hash-with-default-proc
      stats.deep_clear_default!(results)
      results
    end

  end
end
