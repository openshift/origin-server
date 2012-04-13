class ApplicationController < ActionController::Base
  protect_from_forgery

  def session_user
    # return the current authenticated user or nil
  end
  def require_login
    # this method should test authentication, or redirect the user
    # to the correct location
  end
  def logged_in?
    not session_user.nil?
  end
end
