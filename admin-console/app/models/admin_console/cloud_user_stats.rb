module AdminConsole
  class CloudUserStats < CloudUser
    include StatisticGenerator

    def self.gears_per_user_binning
      binning_from_mongo_aggregate(collection.aggregate(
        {
          "$project" => {
            "consumed_bin" => { "$cond" => [{"$lt" => ["$consumed_gears",100]},"$consumed_gears",100]}
          }
        },
        {
          "$group" => {
            "_id" => "$consumed_bin",
            "count" => { "$sum" => 1 }
          }
        }))
    end
  end
end