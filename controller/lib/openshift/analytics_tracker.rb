module OpenShift
  ##
  # This class provides support to plugin different analytics providers.
  class AnalyticsTracker

    attr_reader :analytics_provider_instance

    @@oo_analytics_provider = nil

    ##
    # Switch the Analytics plugin class.
    #
    # @param provider_class [Class] Class that extends OpenShift::AnalyticsTracker.
    def self.provider=(provider_class)
      @@oo_analytics_provider = provider_class
    end

    def initialize(request)
      @analytics_provider_instance = @@oo_analytics_provider.new(request) if @@oo_analytics_provider
    end

    ##
    # Identify a user with an option to push immediately or allow a later track event to be associated
    #
    # @param user [CloudUser] - The user being identified
    def identify(user, push=true)
      analytics_provider_instance.identify(user) if analytics_provider_instance && Rails.configuration.analytics[:enabled]
    end

    ##
    # Track an event for a previously identified user
    #
    # @param event [String] - The name of the event
    # @param membership [Domain or Team] - The domain or team being tracked (optional)
    # @param application [Application] - The application being tracked (optional)
    # @param props [Hash] - Additional properties to track
    def track_event(event, membership=nil, application=nil, props=nil)
      analytics_provider_instance.track_event(event, membership, application, props) if analytics_provider_instance && Rails.configuration.analytics[:enabled]
    end

    ##
    # Track an event for a previously identified user
    #
    # @param event [String] - The name of the event
    # @param user [CloudUser] - The user being tracked
    # @param props [Hash] - Additional properties to track
    def track_user_event(event, user, props=nil)
      analytics_provider_instance.track_user_event(event, user, props) if analytics_provider_instance && Rails.configuration.analytics[:enabled]
    end

  end
end
