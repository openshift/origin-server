module AdminConsole
  class Profile

    def self.find(id)
      self.all[id] || self.all[id.to_sym]
    end

    def self.all
      debug_data = Rails.application.config.admin_console[:debug_profile_data]
      return JSON.parse(File.read(debug_data), :symbolize_names => true) if debug_data.present?
      AdminConsole::Stats.systems_summaries[:profile_summaries_hash]
    end
  end
end

