module AdminConsole
  class NodesController < ApplicationController
    rescue_from OpenShift::NodeException, :with => :page_not_found

    def show
      @id = params[:id]
      @node = OpenShift::ApplicationContainerProxy.instance(@id).get_node_details %w[
          gears_usage_pct
          gears_active_usage_pct
          max_active_gears
          gears_started_count
          gears_idle_count
          gears_stopped_count
          gears_deploying_count
          gears_unknown_count
          gears_total_count
          gears_active_count
          node_profile
          district_uuid
          district_active
          public_ip
          public_hostname
        ]
    end

    protected
      def page_not_found(e=nil, message=nil, alternatives=nil)
        message = "Node #{@id} did not respond.  It may not exist or is currently unavailable."
        super(e, message, alternatives)
      end
  end
end
