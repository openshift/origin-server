class Console::UserController < ConsoleController
  layout 'console'

  before_filter :require_login, :only => :show

  def show
    @user = session_user
    @domain = Domain.find :first, :as => session_user
    @keys = Key.find(:all, :as => session_user)
    render :layout => 'console'
  end
end
