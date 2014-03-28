module AdminConsole
  module Api
    module Search
      class UsagesController < ApiController

        def index
          raise_on_incompatible_parameters :app_name, :app_name_regex
          query = {}
          query[:user_id] = params[:user_id] unless params[:user_id].blank?
          query[:gear_id] = params[:gear_id] unless params[:gear_id].blank?
          query[:app_name] = params[:app_name] unless params[:app_name].blank?
          query[:app_name] = Regexp.new(params[:app_name_regex]) unless params[:app_name_regex].blank?
          raise UnprocessableEntity.new("The parameters specified produced a query which would return all objects, please provide a more specific query.") if query.empty?
          result_limit = params[:limit] ? params[:limit].to_i : MAX_RESULTS
          records = Usage.with(:read => :secondary_preferred).where(query).limit(result_limit + 1)
          respond_with build_response(records.entries.take(result_limit), records.size > result_limit)
        end

      end
    end
  end
end