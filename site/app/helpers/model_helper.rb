module ModelHelper
  def gear_group_states(states)
    return states[0].to_s.humanize if states.uniq.length == 1
    "#{states.filter{ |s| s == :started }.length}/#{states.length} started"
  end
  def gear_group_state(states)
    css_class = if states.all? {|s| s == :started}
        'state_started'
      elsif states.none? {|s| s == :started}
        'state_stopped'
      end

    content_tag(:span, gear_group_states(states), :class => css_class)
  end
end
