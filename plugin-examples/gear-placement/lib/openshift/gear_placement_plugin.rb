#
# This plugin can customize the node selection algorithm used to determine where a gear resides 
#

module OpenShift
  class GearPlacementPlugin

    # Takes in a list of nodes and the relevant information related to the app/user/gear/components 
    # and returns a single node where the gear will reside
    #
    # INPUTS:
    # * server_infos: Array of server information (array of objects of class NodeProperties)
    # * app_props: Properties of the application to which gear is being added (object of class ApplicationProperties)
    # * current_gears: Array of existing gears in the application (objects of class GearProperties)
    # * comp_list: Array of components that will be present on the new gear (objects of class ComponentProperties)
    # * user_props: Properties of the user (object of class UserProperties)
    # * request_time: the time that the request was sent to the plugin
    #
    # RETURNS:
    # * NodeProperties: the server information for a single node where the gear will reside
    #
    def self.select_best_fit_node_impl(server_infos, app_props, current_gears, comp_list, user_props, request_time)
      return server_infos.first
    end
  end
end
