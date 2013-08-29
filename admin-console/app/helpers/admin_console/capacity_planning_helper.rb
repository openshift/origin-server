module AdminConsole
  module CapacityPlanningHelper
    def capacity_overview_sample_profile

      profile = Admin::Stats::HashWithReaders.new.merge({
        :profile => "small",
        :district_count => 24,
        :nodes_count => 72,
        :districts => [],
        :district_capacity => 144000,
        :gears_total_count => 61920,
        :gears_active_count => 5961,
        :available_active_gears_with_negatives => 519,
        :effective_available_gears => 519
      })
      prng = Random.new(11123)
      24.times do |ind|
        nodes = []
        3.times do |ind|
          nodes << {:max_active_gears => 90, :gears_active_usage_pct => prng.rand * 110}
        end
        profile.districts << {:name => ind.to_s, :dist_usage_pct => prng.rand * 100, :nodes => nodes}
      end
      profile
    end

    def sample_tooltip(is_sample, msg_key, classes = [], &block)
      return content_tag(:div, {:class => classes.join(" ").html_safe}, &block) unless is_sample

      message = case msg_key
        when "district_count"
          "The number of districts in this gear size."
        when "total_gears"
          "The total number of gears for this gear size. Includes all active, idled, stopped, deploying, etc. gears."
        when "max_total_gears"
          "Districts have a maximum number of gears that can be added to them. The maximum number of gears for a gear size is the sum of the max for each district in that gear size."
        when "total_progress"
          "This bar indicates the ratio of total gears to max gears for this gear size."
        when "total_heat_map"
          "Each district has a percent usage based on the number of gears already used in the district relative to its maximum. The heat map shows how many districts are at a particular level of percent usage based on the intensity of the color."
        when "node_count"
          "The number of nodes in this gear size."
        when "active_gears"
          "The number of active gears for this gear size. Active gears are allocated system resources."
        when "max_active_gears"
          "Each node has a maximum number of active gears. This maximum is not a hard limit, as idled or stopped gears on the node could become active again. Nodes over their max active gear limit will not accept any new gears. If the maximum number of active gears on the profile has been reached, then either all nodes have reached their maximum active capacity, or some nodes may be over their active capacity."
        when "active_progress"
          "This bar indicates the ratio of active gears to max active gears for this gear size.  If the ratio is above a configurable warning threshold then the portion above the threshold will be shown in orange."
        when "active_heat_map"
          "Each node has a percent active usage based on the number of active gears on the node relative to the maximum active gears allowed. This percentage can be larger than 100%. The heat map shows how many nodes are at a particular level of percent active usage based on the intensity of the color. A configurable warning threshold controls when then nodes transition to orange, and any nodes over 100% active usage will be red."
        else
          ""
        end

      classes << "tooltip-handle"
      content_tag(:div, opts = {
        :class => classes.join(" ").html_safe,
        "data-toggle" => "tooltip",
        :title => message,
        :tabindex => 0
      }, &block)
    end
  end
end