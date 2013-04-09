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

  def web_cartridge_scale_title(cartridge)
    if cartridge.current_scale == cartridge.scales_from
      'Your web cartridge is running on the minimum amount of gears and will scale up if needed'
    elsif cartridge.current_scale == cartridge.scales_to
      'Your web cartridge is running on the maximum amount of gears and cannot scale up any further'
    else
      'Your web cartridge is running multiple copies to handle increased web traffic'
    end
  end

  def cartridge_gear_group_count(group)
    return 'None' if group.gears.empty?
    "#{group.gears.length} #{group.gear_profile.to_s.humanize.downcase}"
  end

  def gear_group_count_title(total_gears)
    "OpenShift runs each cartridge inside one or more gears on a server and is allocated a fixed portion of CPU time and memory use."
  end

  def cartridge_storage(cart)
    storage_string(cart.total_storage)
  end

  def scaled_cartridge_storage(cart)
    storage_string(cart.total_storage, cart.current_scale)
  end

  def storage_string(quota,multiplier = 0)
    parts = []
    if multiplier > 1
      parts << "#{multiplier} x"
    end
    parts << "%s GB" % quota
    parts.join(' ').strip
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
      {:as => :string}
    end
  end
  def scale_to_options(obj, max, max_choices=20)
    if range = scale_range(obj.supported_scales_from, obj.supported_scales_to, max, max_choices)
      range << ['All available', -1] if obj.supported_scales_to == -1
      {:as => :select, :collection => range, :include_blank => false}
    else
      {:as => :string, :hint => 'Use -1 to scale to your current account limits'}
    end
  end

 def storage_options(min,max)
    {:as => :select, :collection => (min..max), :include_blank => false}
  end

  def scale_options
    [['No scaling',false],['Scale with web traffic',true]]
  end

  def can_scale_application_type(type, capabilities)
    type.scalable?
  end

  def cannot_scale_title(type, capabilities)
    unless can_scale_application_type(type, capabilities)
      "This application shares filesystem resources and can't be scaled."
    end
  end

  def user_currency_symbol
    "$"
  end

  def usage_rate_indicator
    content_tag :span, user_currency_symbol, :class => "label label-premium", :title => 'May include additional usage fees at certain levels, see plan for details.'
  end

  def in_groups_by_tag(ary, tags)
    groups = {}
    other = ary.reject do |t|
      tags.any? do |tag|
        (groups[tag] ||= []) << t if t.tags.include?(tag)
      end
    end
    groups = tags.map do |tag|
      types = groups[tag]
      if types
        if types.length < 2
          other.concat(types)
          nil
        else
          [tag, types]
        end
      end
    end.compact
    [groups, other]
  end

  def common_tags_for(ary)
    ary.length < 2 ? [] : ary.inject(nil){ |tags, a| tags ? (a.tags & tags) : a.tags } || []
  end
end
