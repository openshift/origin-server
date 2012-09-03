class ConsoleController < Console.config.parent_controller.constantize
  include Console::Auth::Passthrough unless Console.config.disable_passthrough
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
end
