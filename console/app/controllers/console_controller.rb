class ConsoleController < Console.config.parent_controller.constantize
  include Console::Auth::Passthrough unless Console.config.disable_passthrough
  include DomainAware
  include SshkeyAware

  layout 'console'

  before_filter :authenticate_user!

  def active_tab
    nil
  end

  protected
    def upgrade_in_rails_31
      raise "Code needs upgrade for rails 3.1+" if Rails.version[0..3] != '3.0.'
    end

  private
    def help
    end
end
