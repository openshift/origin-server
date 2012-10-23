module OpenShift
  module KerberosAuthServiceModule
    require 'openshift-origin-auth-kerberos/engine/engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift-origin-auth-kerberos/lib/openshift/kerberos_auth_service.rb"
OpenShift::AuthService.provider=OpenShift::KerberosAuthService
