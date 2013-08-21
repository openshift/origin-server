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

    def self.systems_summaries(force_reload = false, conf = Rails.application.config.admin_console[:stats])
      Rails.cache.fetch('admin_console_system_statistics',
                        expires_in: conf[:cache_timeout],
                        force: force_reload) do
        gather_systems_statistics(conf)
      end
    end

    protected

    # Create system stats via Admin::Stats according to conf.
    # Time of generation/loading is stored in 'created_at' key.
    def self.gather_systems_statistics(conf = {})
      stats = Admin::Stats.new wait: conf[:mco_timeout],
                          read_file: conf[:read_file]
      stats.gather_statistics
      stats.results.merge 'created_at' => Time.now
    end

  end
end
