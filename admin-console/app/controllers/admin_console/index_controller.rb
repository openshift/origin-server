require_dependency "admin_console/application_controller"

module AdminConsole
  class IndexController < ApplicationController
    def index
      @nodes = OpenShift::MCollectiveApplicationContainerProxy.get_all_nodes_details
    end
  end
end
