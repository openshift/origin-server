module AdminConsole
  class ApplicationStats < Application
    include StatisticGenerator

    def self.apps_per_domain_binning
      binning_from_mongo_aggregate(collection.aggregate(
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
        }))
    end
  end
end