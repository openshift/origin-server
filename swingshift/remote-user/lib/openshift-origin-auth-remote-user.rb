module Swingshift
  module AuthService
    require 'openshift-origin-auth-remote-user/engine/engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift-origin-auth-remote-user/lib/swingshift/remote_user_auth_service.rb"
StickShift::AuthService.provider=Swingshift::RemoteUserAuthService
