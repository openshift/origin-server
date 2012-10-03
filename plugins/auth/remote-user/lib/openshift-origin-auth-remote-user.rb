module Swingshift
  module AuthService
    require 'openshift-origin-auth-remote-user/engine/engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift-origin-auth-remote-user/lib/openshift/remote_user_auth_service.rb"
OpenShift Origin::AuthService.provider=Swingshift::RemoteUserAuthService
