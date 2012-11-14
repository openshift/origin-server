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

  protected
    def to_boolean(param)
      ['1','on','true'].include?(param.to_s.downcase) if param
    end
end
