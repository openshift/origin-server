module AdminConsole
  module Api
    module Search
      class DomainsController < ApiController

        def index
          raise_on_incompatible_parameters :namespace, :namespace_regex
          query = {}
          query[:_id] = params[:id] unless params[:id].blank?
          query[:owner_id] = params[:owner_id] unless params[:owner_id].blank?
          query[:namespace] = params[:namespace] unless params[:namespace].blank?
          query[:namespace] = Regexp.new(params[:namespace_regex]) unless params[:namespace_regex].blank?
          raise UnprocessableEntity.new("The parameters specified produced a query which would return all objects, please provide a more specific query.") if query.empty?
          result_limit = params[:limit] ? params[:limit].to_i : MAX_RESULTS
          records = Domain.with(:read => :secondary_preferred).where(query).limit(result_limit + 1)
          respond_with build_response(records.entries.take(result_limit), records.size > result_limit)
        end

      end
    end
  end
end