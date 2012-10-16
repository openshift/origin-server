module Console::ModelHelper
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

  def cartridge_gear_group_count(group)
    return 'None' if group.gears.empty?
    "#{group.gears.length} #{group.gear_profile.to_s.humanize.downcase}"
  end

  def gear_group_count_title(total_gears)
    "OpenShift runs each cartridge inside one or more gears on a server and is allocated a fixed portion of CPU time and memory use."
  end

  def scale_range(from, to, max, max_choices)
    limit = to == -1 ? max : to
    return if limit > max_choices
    (from .. limit).map{ |i| [i.to_s, i] }
  end
  def scale_from_options(obj, max, max_choices=20)
    if range = scale_range(obj.supported_scales_from, obj.supported_scales_to, max, max_choices)
      {:as => :select, :collection => range, :include_blank => false}
    else
      {:as => :text}
    end
  end
  def scale_to_options(obj, max, max_choices=20)
    if range = scale_range(obj.supported_scales_from, obj.supported_scales_to, max, max_choices)
      range << ['All available', -1] if obj.supported_scales_to == -1
      {:as => :select, :collection => range, :include_blank => false}
    else
      {:as => :text, :hint => 'Use -1 to scale to your current account limits'}
    end
  end
end
