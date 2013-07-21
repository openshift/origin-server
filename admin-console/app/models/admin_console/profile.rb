module AdminConsole
  class Profile

    def self.find(id)
      self.all[id]
    end

    def self.all
      Stats.systems_summaries[:profile_summaries_hash]
    end

  end
end
