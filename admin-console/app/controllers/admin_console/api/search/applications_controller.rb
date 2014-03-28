module AdminConsole
  module Api
    module Search
      class ApplicationsController < ApiController

        def index
          raise_on_incompatible_parameters :name, :name_regex
          raise_on_incompatible_parameters :namespace, :namespace_regex
          raise_on_incompatible_parameters :fqdn, :fqdn_regex
          query = {}
          query["gears.uuid"] = params[:gear_uuid] if params[:gear_uuid]
          query[:domain_id] = params[:domain_id] unless params[:domain_id].blank?
          query[:name] = params[:name] unless params[:name].blank?
          query[:name] = Regexp.new(params[:name_regex]) unless params[:name_regex].blank?
          query[:domain_namespace] = params[:namespace] unless params[:namespace].blank?
          query[:domain_namespace] = Regexp.new(params[:namespace_regex]) unless params[:namespace_regex].blank?
          query[:_id] = params[:id] unless params[:id].blank?
          query["aliases.fqdn"] = params[:fqdn] unless params[:fqdn].blank?
          query["aliases.fqdn"] = Regexp.new(params[:fqdn_regex]) unless params[:fqdn_regex].blank?
          raise UnprocessableEntity.new("The parameters specified produced a query which would return all objects, please provide a more specific query.") if query.empty?
          result_limit = params[:limit] ? params[:limit].to_i : MAX_RESULTS
          records = Application.with(:read => :secondary_preferred).where(query).limit(result_limit + 1)
          respond_with build_response(records.entries.take(result_limit), records.size > result_limit)
        end

      end
    end
  end
end