class ConsoleController < Console.config.parent_controller.constantize
  include Console.config.security_controller.constantize
  include CapabilityAware
  include DomainAware
  include SshkeyAware
  include CostAware
  include Console::CommunityAware
  include Console::LogHelper
  include Console::ErrorsHelper

  layout 'console'

  before_filter :authenticate_user!

  protected
    def active_tab
      nil
    end
    helper_method :active_tab

    def to_boolean(param)
      ['1','on','true'].include?(param.to_s.downcase) if param
    end

    def valid_referrer(referrer)
      referrer = (URI.parse(referrer) rescue nil) if referrer.is_a? String
      case
      when referrer.nil?, remote_request?(referrer)
        nil
      when !referrer.path.start_with?('/')
        nil
      else
        referrer.to_s
      end
    end

    def remote_request?(referrer)
      referrer.present? && referrer.host && !(request.host == referrer.host || referrer.host == URI.parse(community_url).host)
    end

end
