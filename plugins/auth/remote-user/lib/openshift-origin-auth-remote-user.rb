module OpenShift
  module RemoteUserAuthServiceModule
    require 'openshift-origin-auth-remote-user/engine/engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift-origin-auth-remote-user/lib/openshift/remote_user_auth_service.rb"
OpenShift::AuthService.provider=OpenShift::RemoteUserAuthService
