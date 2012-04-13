class ConsoleController < ActionController::Base
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
