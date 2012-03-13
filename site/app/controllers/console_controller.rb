class ConsoleController < ApplicationController

  layout 'console'

  before_filter :require_login
  before_filter :new_forms

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
