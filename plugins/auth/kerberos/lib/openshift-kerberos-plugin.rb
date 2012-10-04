module Swingshift
  module AuthService
    require 'swingshift-kerberos-plugin/engine/engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "swingshift-kerberos-plugin/lib/swingshift/kerberos_auth_service.rb"
StickShift::AuthService.provider=Swingshift::KerberosAuthService
