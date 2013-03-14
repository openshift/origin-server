class ApplicationController < ActionController::Base
  include Console::Rescue

  protect_from_forgery

  protected
    def account_settings_redirect
      account_path
    end
end
