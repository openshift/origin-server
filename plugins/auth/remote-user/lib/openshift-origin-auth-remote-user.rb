module OpenShift
  module RemoteUserAuthServiceModule
    require 'engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift/remote_user_auth_service.rb"
OpenShift::AuthService.provider=OpenShift::RemoteUserAuthService
