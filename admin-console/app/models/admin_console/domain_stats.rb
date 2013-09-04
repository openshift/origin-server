module AdminConsole
  class DomainStats < Domain
    include StatisticGenerator

    def self.domains_per_user_binning
      return binning_from_mongo_aggregate([{"_id" => 0, "count" => CloudUser.count}]) unless Domain.count > 0
      binning = binning_from_mongo_aggregate(collection.aggregate([
        {
          "$group" => {
            "_id" => "$owner_id",
            "count" => { "$sum" => 1 }
          }
        },
        {
          "$project" => {
            "domain_per_user_bin" => { "$cond" => [{"$lt" => ["$count",100]},"$count",100]}
          }
        },
        {
          "$group" => {
            "_id" => "$domain_per_user_bin",
            "count" => { "$sum" => 1 }
          }
        }]))
      total_users_found = binning[:bins].inject(0) { |sum, bin| sum + bin[:count] }
      zero_bin = binning[:bins].find { |bin| bin[:bin] == 0 }
      zero_bin[:count] = CloudUser.count - total_users_found
      binning
    end
  end
end