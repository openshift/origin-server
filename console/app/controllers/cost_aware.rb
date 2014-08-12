# encoding: UTF-8
module CostAware
  extend ActiveSupport::Concern

  included do
    include Console::CostHelper
    helper_method :user_currency_symbol, :user_currency_cd, :number_to_user_currency, :gear_increase_cost, :gear_types_with_cost, :has_gear_types_with_cost, :gear_sizes_and_rates, :fixup_rate, :cartridges_premium
  end

  protected
    def user_currency_cd
      'usd'
    end

    def user_currency_symbol
      case user_currency_cd
      when "eur"
        "€"
      when "cad"
        "C$"
      else
        "$"
      end
    end

    def number_to_user_currency(number, truncate=true)
      return nil if number.nil?

      case user_currency_cd
      when 'eur'
        unit = "€"
        format = "%u %n"
      when 'cad'
        unit = "C$"
        format = "%u%n"
      else
        unit = "$"
        format = "%u%n"
      end

      options = {}
      options[:unit] = unit
      options[:format] = format
      if !truncate && number > 0 && (number % 1) != 0
        # Set precision to fully display the number (min of 2, max of 6)
        fraction_string = number.to_s.sub(/^.*\.([0-9]*?)0*$/, '\1')
        options[:precision] = [2, fraction_string.length, 6].sort[1]
      end
      number_to_currency(number, options)
    end

    # Method to calculate the correct rate in case of very small rates that got rounded to 0.00 incorrectly
    def fixup_rate(rate, units, amount)
      (rate == 0 && units != 0 && amount != 0) ? (amount / units) : rate
    end

    # count - number of new gears
    # capabilities - capabilities from related user or domain
    # usage_rates - usage_rates from related user or domain
    def gear_increase_cost(count, capabilities, usage_rates)
      false
    end

    # usage_rates - usage_rates from related user or domain
    def gear_types_with_cost(usage_rates)
      []
    end

    # applications - list of applications to check
    # usage_rates - usage_rates from related user or domain
    def has_gear_types_with_cost(applications, usage_rates)
      false
    end

    # cartridges - list of cartridges
    # usage_rates - usage_rates from related user or domain
    def cartridges_premium(cartridges, usage_rates)
      return cartridges.any?{ |(_, carts)| carts.any?{ |c| c.usage_rates.present? } } if cartridges.is_a? Hash
    end

    # sizes: ['size1', 'size2', ...]
    # rates: {'size1' => {'usd' => 0.1, 'duration' => 'hour'}}
    def gear_sizes_and_rates(sizes, rates)
      (sizes || []).map do |size|
        rate = rates[size][user_currency_cd] rescue nil
        duration = rates[size]['duration'] rescue nil
        if rate and duration
          "#{size} (#{number_to_user_currency(rate, false)}/#{duration})"
        else
          size
        end
      end
    end

  private
    include ActionView::Helpers::NumberHelper
end
