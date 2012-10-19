class ConsoleController < Console.config.parent_controller.constantize
  include Console.config.security_controller.constantize
  include CapabilityAware
  include DomainAware
  include SshkeyAware

  layout 'console'

  before_filter :authenticate_user!

  def active_tab
    nil
  end

  private
    def help
    end
    def unauthorized
    end
end
