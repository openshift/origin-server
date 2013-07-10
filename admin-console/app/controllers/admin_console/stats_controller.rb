require_dependency "admin_console/application_controller"

module AdminConsole
  class StatsController < ApplicationController
    respond_to :json

    def index
      @stats = {
        :application => {
          :total => Application.count
        },
        :user => {
          :total => CloudUser.count
        }
        #TODO node
      }
    end

    # rest api that collects the advanced, long-running statistics
    def advanced
      gears_per_user = CloudUser.collection.aggregate(
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
        })

      apps_per_domain = Application.collection.aggregate(
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
        })

      respond_with({:apps_per_domain => apps_per_domain, :gears_per_user => gears_per_user})
    end
  end
end
