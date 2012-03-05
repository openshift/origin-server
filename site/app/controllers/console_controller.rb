class ConsoleController < ApplicationController

  layout 'console'

  before_filter :require_login
  before_filter :new_forms

  def index
    redirect_to applications_path
  end

  private
    def help
    end
end
