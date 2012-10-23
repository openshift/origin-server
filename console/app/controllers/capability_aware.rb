module CapabilityAware
  extend ActiveSupport::Concern

  included do
    around_filter UserSessionSweeper
  end

  # Call this with :refresh => true to force a
  # refresh of the values stored in session
  def user_capabilities(args = {})
    if args[:refresh] or not session.has_key?(:user_capabilities)
      user = User.find(:one, :as => current_user)
      session[:user_capabilities] = [
        user.max_gears,
        user.consumed_gears,
        user.capabilities.gear_sizes
      ]
    end
    { :max_gears => session[:user_capabilities][0],
      :consumed_gears => session[:user_capabilities][1],
      :gear_sizes => session[:user_capabilities][2]
    }
  end
end
RestApi::Base.observers << UserSessionSweeper
UserSessionSweeper.instance
