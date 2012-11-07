module OpenShift
  module RemoteUserAuthServiceModule
    require 'remote_user_auth_engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift/remote_user_auth_service.rb"
OpenShift::AuthService.provider=OpenShift::RemoteUserAuthService
