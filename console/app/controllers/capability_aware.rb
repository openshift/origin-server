module CapabilityAware
  extend ActiveSupport::Concern

  included do
    around_filter UserSessionSweeper
  end

  def user_capabilities_gear_sizes
    if gear_sizes = session[:capabilities_gear_sizes]
      logger.debug "  Using cached gear sizes: #{gear_sizes}"
      gear_sizes
    else
      User.find(:one, :as => current_user).capabilities.gear_sizes do |gear_sizes|
        session[:capabilities_gear_sizes] = gear_sizes
      end
    end
  end

  def user_max_gears
    if max_gears = session[:max_gears]
      logger.debug "  Using cached max gears: #{max_gears}"
      max_gears
    else
      session[:max_gears] = User.find(:one, :as => current_user).max_gears
    end
  end

  def user_consumed_gears
    gear_total = 0
    User.find(:one, :as => current_user).consumed_gear_sizes.attributes.each do |gear_size,gear_count|
      gear_total += gear_count
    end
    gear_total
  end
end
RestApi::Base.observers << UserSessionSweeper
UserSessionSweeper.instance
