require_dependency "admin_console/application_controller"

module AdminConsole
  class NodesController < ApplicationController
    rescue_from OpenShift::NodeException, :with => :page_not_found

    def show
      @id = params[:id]
      @node = OpenShift::ApplicationContainerProxy.instance(@id).get_node_details
    end

    protected
      def page_not_found(e=nil, message=nil, alternatives=nil)
        message = "Node #{@id} did not respond.  It may not exist or is currently unavailable."
        super(e, message, alternatives)
      end
  end
end