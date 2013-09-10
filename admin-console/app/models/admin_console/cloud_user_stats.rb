module AdminConsole
  class CloudUserStats < CloudUser
    include StatisticGenerator

    def self.gears_per_user_binning
      return binning_from_mongo_aggregate([{"_id" => 0, "count" => CloudUser.count}]) unless Application.count > 0
      binning_from_mongo_aggregate(collection.aggregate([
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
        }]))
    end
  end
end