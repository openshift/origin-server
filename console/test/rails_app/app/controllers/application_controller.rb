class ApplicationController < ActionController::Base
  include Console::Rescue

  protect_from_forgery
end
