module CapabilityAware
  extend ActiveSupport::Concern

  included do
    around_filter UserSessionSweeper
  end

  def current_api_user
    @current_api_user ||= begin
        @user_capabilities = nil
        session[:caps] = nil
        User.find :one, :as => current_user
      end
  end

  # Call this with :refresh => true to force a
  # refresh of the values stored in session
  def user_capabilities(args = {})
    if args[:refresh] || args[:clear]
      @user_capabilities = nil
      session[:caps] = nil
      return if args[:clear]
    end
    model = Console.config.capabilities_model_class
    @user_capabilities ||=
      (model.from(session[:caps]) rescue nil) ||
      model.from(current_api_user).tap{ |c| session[:caps] = c.to_session }
  end
end
RestApi::Base.observers << UserSessionSweeper
UserSessionSweeper.instance
