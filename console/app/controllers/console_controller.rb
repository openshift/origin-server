class ConsoleController < Console.config.parent_controller.constantize
  include Console::Auth::Passthrough unless Console.config.disable_passthrough

  protect_from_forgery

  layout 'console'

  before_filter :require_login

  def index
    redirect_to applications_path
  end

  def active_tab
    nil
  end

  private
    def help
    end
end
