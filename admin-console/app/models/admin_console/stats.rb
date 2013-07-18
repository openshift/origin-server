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
  end
end