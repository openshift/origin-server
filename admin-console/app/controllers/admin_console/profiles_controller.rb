module AdminConsole
  class ProfilesController < ApplicationController
    respond_to :json, :xml
    def show
      @id = params[:id]
      stats = AdminConsole::Stats.systems_summaries
      @profile = stats[:profile_summaries_hash][@id]
      @stats_created_at = stats[:created_at]

      return page_not_found unless @profile.present?

      load_topology
    end

    def index
      reload = params[:reload]
      stats = AdminConsole::Stats.systems_summaries(reload)
      respond_with stats[:profile_summaries_hash]
    end

    def show_nodes
      @show_nodes = true
      @id = params[:id]
      reload = params[:reload]
      stats = AdminConsole::Stats.systems_summaries(reload)
      @profile = stats[:profile_summaries_hash][@id]
      @stats_created_at = stats[:created_at]

      return page_not_found unless @profile.present?

      load_topology
      render :show
    end

    protected

      def load_topology
        @config = Rails.application.config.admin_console
        @cache_timeout = @config[:stats][:cache_timeout]
        @active_warning_threshold = @config[:warn][:node_active_remaining]

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
        active_warning_threshold = @config[:warn][:node_active_remaining]
        sort = if @active_sort == 'total'
          if @active_sort_direction == 'desc'
            lambda{ |s| s[:dist_avail_capacity] }
          else
            lambda{ |s| -s[:dist_avail_capacity] }
          end
        else
          if @active_sort_direction == 'desc'
            lambda{ |s| -(active_warning_threshold * s[:nodes].size - s[:available_active_gears_with_negatives]) }
          else
            lambda{ |s| (active_warning_threshold * s[:nodes].size - s[:available_active_gears_with_negatives]) }
          end
        end

        sort.call(x) <=> sort.call(y)
      end
  end
end
