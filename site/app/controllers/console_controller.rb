class ConsoleController < ApplicationController

  layout 'console'

  before_filter :authenticate_user!
  include DomainAware

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
