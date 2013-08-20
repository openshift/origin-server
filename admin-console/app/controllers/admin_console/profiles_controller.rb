require_dependency "admin_console/application_controller"

module AdminConsole
  class ProfilesController < ApplicationController
    respond_to :json, :xml
    def show
      @id = params[:id]
      @profile = Profile.find @id
      return page_not_found unless @profile.present?

      setup_additional_information_for_show
    end

    def index
      respond_with Profile.all
    end

    def show_nodes
      @show_nodes = true
      @id = params[:id]
      @profile = Profile.find @id
      return page_not_found unless @profile.present?

      setup_additional_information_for_show
      render :show
    end

    protected

    def setup_additional_information_for_show
      @config = Rails.application.config.admin_console 

      @undistricted_nodes_exist = @profile[:districts].any? {|district| district[:name] == "(NONE)"}
      @districts_exist = Rails.configuration.msg_broker[:districts][:enabled] && 
                        (@profile[:districts].size > 1 || !@undistricted_nodes_exist)
      @show_nodes |= !@districts_exist

      @active_sort = params[:sk].nil? ? (@show_nodes ? 'active' : 'total') : params[:sk]
      @active_sort_direction = params[:so].nil? ? 'desc' : params[:so]

      if (@show_nodes)
        @nodes = []
        @profile[:districts].each { |district| @nodes.concat district[:nodes] }
        @nodes = @nodes.sort { |x, y| sort_nodes(x, y)}
        @district_uuid_filter = params[:district]
      else
        @districts = @profile[:districts].sort { |x, y| sort_districts(x, y)}
      end
    end

    def page_not_found(e=nil, message=nil, alternatives=nil)
      message = "Gear profile #{@id} not found"
      super(e, message, alternatives)
    end

    def sort_nodes(x, y)
      if @active_sort_direction == 'desc'
        return y[:gears_active_count] <=> x[:gears_active_count]
      end

      x[:gears_active_count] <=> y[:gears_active_count]
    end

    def sort_districts(x, y)
      if (@active_sort == 'total')
        if @active_sort_direction == 'desc'
          return y[:gears_total_count] <=> x[:gears_total_count]
        end

        return x[:gears_total_count] <=> y[:gears_total_count]
      else
        if @active_sort_direction == 'desc'
          return x[:available_active_gears_with_negatives] <=> y[:available_active_gears_with_negatives]
        end

        y[:available_active_gears_with_negatives] <=> x[:available_active_gears_with_negatives]
      end
    end
  end
end
