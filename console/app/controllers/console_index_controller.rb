class ConsoleIndexController < ConsoleController
  skip_before_filter :authenticate_user!, :only => [:unauthorized, :server_unavailable]

  def index
    flash.keep
    redirect_to applications_path
  end
  def unauthorized
    render 'console/unauthorized'
  end
  def server_unavailable
    render 'console/server_unavailable'
  end
  def help
    render 'console/help'
  end
end
