module OpenShift
  module KerberosAuthServiceModule
    require 'engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift/kerberos_auth_service.rb"
OpenShift::AuthService.provider=OpenShift::KerberosAuthService
