module AdminConsole
  class ApplicationStats < Application
    include StatisticGenerator

    def self.apps_per_domain_binning
      return binning_from_mongo_aggregate([{"_id" => 0, "count" => Domain.count}]) unless Application.count > 0

      binning_from_mongo_aggregate(collection.aggregate([
        {
          "$group" => {
            "_id" => "$domain_id",
            "count" => { "$sum" => 1 }
          }
        },
        {
          "$project" => {
            "app_per_domain_bin" => { "$cond" => [{"$lt" => ["$count",100]},"$count",100]}
          }
        },
        {
          "$group" => {
            "_id" => "$app_per_domain_bin",
            "count" => { "$sum" => 1 }
          }
        }]))
    end
  end
end