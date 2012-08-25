module ModelHelper
  def gear_group_states(states)
    return states[0].to_s.humanize if states.uniq.length == 1
    "#{states.count{ |s| s == :started }}/#{states.length} started"
  end
  def gear_group_state(states)
    css_class = if states.all? {|s| s == :started}
        'state_started'
      elsif states.none? {|s| s == :started}
        'state_stopped'
      end

    content_tag(:span, gear_group_states(states), :class => css_class)
  end

  def gear_group_count(gears)
    types = gears.inject({}){ |h,g| h[g.gear_profile.to_s] ||= 0; h[g.gear_profile.to_s] += 1; h }
    return 'None' if types.empty?
    types.keys.sort.map do |k|
      "#{types[k]} #{k.humanize.downcase}"
    end.to_sentence
  end

  def gear_group_count_title(cart, total_gears)
    extra_gears = total_gears - cart.gear_count
    if extra_gears > 0
      "This cartridge uses #{pluralize(extra_gears, "gear")} to " << begin
        if cart.builds? and cart.scales?
          "handle builds and scaling. The remaining gears run copies of the web cartridge."
        elsif cart.builds?
          "handle builds. The other gear runs the web cartridge"
        elsif cart.scales?
          "scale. The remaining gears run copies of the web cartridge."
        else
          "expose the other cartridges."
        end
      end
    else
      "OpenShift runs each cartridge inside one or more gears on a server and is allocated a fixed portion of CPU time and memory use."
    end
  end
end
