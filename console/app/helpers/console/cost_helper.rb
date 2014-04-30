module Console::CostHelper
  def gear_increase_indicator(cartridges, scales, gear_type, existing, capabilities, usage_rates, yours)
    range = scales ? gear_estimate_for_scaled_app(cartridges) : (existing ? 0..0 : 1..1)
    min = range.begin
    max = range.end
    increasing = (min > 0 || max > 0)
    owner = yours ? "your" : "the domain owner's"
    cost, title =
      if gear_increase_cost(min, capabilities, usage_rates)
        [true, "This will add #{pluralize(min, 'gear')} to #{owner} account and will result in additional charges."]
      elsif gear_increase_cost(max, capabilities, usage_rates)
        [true, "This will add at least #{pluralize(min, 'gear')} to #{owner} account and may result in additional charges."]
      elsif !increasing
        [false, "No gears will be added to #{owner} account."]
      elsif max == Float::INFINITY
        [false, "This will add an unknown number of gears to #{owner} account."]
      elsif min != max
        [false, "This will add between #{min} and #{max} gears to #{owner} account."]
      else
        [false, "This will add #{pluralize(min, 'gear')} to #{owner} account."]
      end
    if cartridges_premium(cartridges, usage_rates)
      cost = true
      title = "#{title} Additional charges may be accrued for premium cartridges."
    end
    if increasing && gear_types_with_cost(usage_rates).include?(gear_type)
      cost = true
      title = "#{title} The selected gear type will have additional hourly charges."
    end

    content_tag(:span,
      [
        (if max == Float::INFINITY
          "+#{min}-?"
        elsif max != min
          "+#{min}-#{max}"
        else
          "+#{min}"
        end),
        "<span data-icon=\"\ue014\" aria-hidden=\"true\"> </span>",
        ("<span class=\"label label-premium\">#{user_currency_symbol}</span>" if cost),
      ].compact.join(' ').html_safe,
      :class => 'indicator-gear-increase',
      :title => title,
    )
  end

  def gear_estimate_for_scaled_app(cartridges)
    min = 0
    max = 0
    if cartridges.present?
      cartridges.each_pair do |_, carts|
        any = false
        all = true
        variable = false
        carts.each do |cart|
          if cart.service? || cart.web_framework?
            any = true
          elsif cart.custom?
            variable = any = true
          else
            all = false
            break if any
          end
        end
        max += 1 if any
        min += 1 if all && !variable
      end
    else
      min = 1
      max = Float::INFINITY
    end
    Range.new(min,max)
  end

  def usage_rate_indicator
    content_tag :span, user_currency_symbol, :class => "label label-premium", :title => 'May include additional usage fees at certain levels, see plan for details.'
  end
end