module CapabilityAware
  extend ActiveSupport::Concern

  included do
    around_filter UserSessionSweeper
  end

  def user_capabilities_gear_sizes
    if gear_sizes = session[:capabilities_gear_sizes]
      logger.debug "  Using cached gear sizes #{gear_sizes}"
      gear_sizes
    else
      User.find(:one, :as => current_user).capabilities.gear_sizes do |gear_sizes|
        session[:capabilities_gear_sizes] = gear_sizes
      end
    end
  end
end
RestApi::Base.observers << UserSessionSweeper
UserSessionSweeper.instance
