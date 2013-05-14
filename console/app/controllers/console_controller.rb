class ConsoleController < Console.config.parent_controller.constantize
  include Console.config.security_controller.constantize
  include CapabilityAware
  include DomainAware
  include SshkeyAware
  include Console::CommunityAware
  include LogHelper

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
end
