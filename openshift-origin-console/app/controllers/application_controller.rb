class ApplicationController < ActionController::Base
  include Console::Rescue

  protect_from_forgery

  protected
    def handle_unverified_request
      raise Console::AccessDenied, "Request authenticity token does not match session #{session.inspect}"
    end
end
