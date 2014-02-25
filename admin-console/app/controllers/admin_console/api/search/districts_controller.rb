module AdminConsole
  module Api
    module Search
      class DistrictsController < ApiController

        def index
          raise_on_incompatible_parameters :name, :name_regex
          query = {}
          query[:uuid] = params[:id] unless params[:id].blank?
          query[:name] = params[:name] unless params[:name].blank?
          query[:name] = Regexp.new(params[:name_regex]) unless params[:name_regex].blank?
          result_limit = params[:limit] ? params[:limit].to_i : MAX_RESULTS
          records = District.with(:read => :secondary_preferred).where(query).only(:name, :uuid, :gear_size, :max_capacity, :max_uid, :available_capacity, :active_servers_size, :servers).limit(result_limit + 1)
          respond_with build_response(records.entries.take(result_limit), records.size > result_limit)
        end

      end
    end
  end
end