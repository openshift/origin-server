#
# This plugin can customize the node selection algorithm used to determine where a gear resides.
#

require 'pp'

module OpenShift
  class GearPlacementPlugin

    # Takes in a list of nodes and the relevant information related to the app/user/gear/components
    # and returns a single node where the gear will reside. This example plugin just logs some
    # debug information and delegates to the default algorithm.
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
      Rails.logger.info("Using gear placement plugin to choose node.")
      Rails.logger.info("selecting from nodes: #{server_infos.map(&:name).join ', '}")
      Rails.logger.info("server_infos: #{server_infos.pretty_inspect}")
      Rails.logger.info("app_props: #{app_props.pretty_inspect}")
      Rails.logger.info("current_gears: #{current_gears.pretty_inspect}")
      Rails.logger.info("comp_list: #{comp_list.pretty_inspect}")
      Rails.logger.info("user_props: #{user_props.pretty_inspect}")
      # choose a node, e.g. randomly:
      selected = server_infos.sample
      # or if nothing special is needed, let the default algorithm choose.
      selected = OpenShift::MCollectiveApplicationContainerProxy.select_best_fit_node_impl(server_infos)
      Rails.logger.info("selected node: '#{selected.name}'")
      return selected
    end
  end
end
