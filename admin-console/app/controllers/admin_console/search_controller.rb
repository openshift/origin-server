module AdminConsole
  class SearchController < ApplicationController
    def index
      #query/scope may or may not exist, if they do, attempt to get the item
      @query = params[:query]
      @scope = params[:scope]
      @item = case @scope
              when "user"
                redirect_to user_path :id => @query
              when "node"
                redirect_to node_path :id => @query
              when "gear"
                redirect_to gear_path :id => @query
              when "application"
                redirect_to application_path :id => @query
              end unless @query.nil? || @query.empty?
      #otherwise just render the search form
    end
  end
end