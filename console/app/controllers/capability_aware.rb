module CapabilityAware
  extend ActiveSupport::Concern

  included do
    around_filter UserSessionSweeper
  end

  # Call this with :refresh => true to force a
  # refresh of the values stored in session
  def user_capabilities(args = {})
    @user_capabilities = nil if args[:refresh]
    @user_capabilities ||=
      (Capabilities::Cacheable.from(session[:user_capabilities]) rescue nil) ||
      User.find(:one, :as => current_user).to_capabilities.tap{ |c| session[:user_capabilities] = c.to_a }
  end
end
RestApi::Base.observers << UserSessionSweeper
UserSessionSweeper.instance
