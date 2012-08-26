class Console::UserController < ConsoleController
  layout 'console'

  before_filter :require_login, :only => :show

  def show
    @user = current_user
    @domain = Domain.find :first, :as => current_user
    @keys = Key.find(:all, :as => current_user)
    render :layout => 'console'
  end
end
