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
       (force_reload ? nil : Rails.cache.read('admin_console_system_statistics')) || gather_systems_statistics
     end

     protected

     def self.gather_systems_statistics
      stats = Admin::Stats.new
      stats.gather_statistics
      results = stats.results.except(:node_entries, :district_entries, :district_summaries, :profile_summaries)
      Rails.cache.write('admin_console_system_statistics', results, {:expires_in => 1.hour})
      # TODO: make cache expiration configurable
      results
     end

  end
end
