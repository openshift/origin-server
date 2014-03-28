module AdminConsole
  module Api
    module Search
      class UsersController < ApiController

        def index
          raise_on_incompatible_parameters :login, :login_regex
          query = {}
          query[:_id] = params[:id] unless params[:id].blank?
          query[:login] = params[:login] unless params[:login].blank?
          query[:login] = Regexp.new(params[:login_regex]) unless params[:login_regex].blank?
          query[:plan_id] = params[:plan_id] unless params[:plan_id].blank?
          query[:usage_account_id] = params[:usage_account_id] unless params[:usage_account_id].blank?
          raise UnprocessableEntity.new("The parameters specified produced a query which would return all objects, please provide a more specific query.") if query.empty?
          result_limit = params[:limit] ? params[:limit].to_i : MAX_RESULTS
          records = CloudUser.with(:read => :secondary_preferred).where(query).limit(result_limit + 1)
          respond_with build_response(records.entries.take(result_limit), records.size > result_limit)
        end

      end
    end
  end
end