class ApplicationController < ActionController::Base
  protect_from_forgery

  # The console by default uses passthrough authentication
  include Console::Auth::Passthrough

end
