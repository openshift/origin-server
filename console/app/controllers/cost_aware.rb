# encoding: UTF-8
module CostAware
  extend ActiveSupport::Concern

  included do
    include Console::CostHelper
    helper_method :user_currency_symbol, :user_currency_cd, :number_to_user_currency, :gear_increase_cost, :gear_types_with_cost, :has_gear_types_with_cost, :gear_sizes_and_rates
  end

  protected
    def user_currency_cd
      :usd
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

    def number_to_user_currency(number)
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
      number_to_currency(number, options)
    end

    def gear_increase_cost(count, capabilities=nil)
      false
    end

    def gear_types_with_cost
      []
    end

    def has_gear_types_with_cost(applications)
      false
    end

    # sizes: ['size1', 'size2', ...]
    # rates: {'size1' => {'usd' => 0.1, 'duration' => 'hour'}}
    def gear_sizes_and_rates(sizes, rates)
      (sizes || []).map do |size|
        rate = rates[size][user_currency_cd] rescue nil
        duration = rates[size]['duration'] rescue nil
        if rate and duration
          "#{size.capitalize} (#{number_to_user_currency(rate)}/#{duration})"
        else
          size.capitalize
        end
      end
    end

  private
    include ActionView::Helpers::NumberHelper
end