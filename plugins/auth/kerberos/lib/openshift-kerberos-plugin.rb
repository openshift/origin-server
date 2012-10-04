module Swingshift
  module AuthService
    require 'openshift-origin-auth-kerberos/engine/engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "openshift-origin-auth-kerberos/lib/openshift/kerberos_auth_service.rb"
OpenShift Origin::AuthService.provider=Swingshift::KerberosAuthService
