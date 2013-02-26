require 'krb5_auth'

module OpenShift
  class KerberosAuthService
    include Krb5Auth

    def authenticate(login, password)
      raise OpenShift::AccessDeniedException if password.blank?
      krb5 = Krb5.new

      # get the default realm
      default_realm = krb5.get_default_realm
      Rails.logger.debug "Default realm is: " + default_realm
      # try to cache non-existant data (this should fail and throw an exception)
      begin
        krb5.cache
      rescue Krb5Auth::Krb5::Exception
        Rails.logger.debug "Failed caching credentials before obtaining them. Continuing..."
      end

      raise OpenShift::AccessDeniedException unless krb5.get_init_creds_password(login, password)
      {:username => login}
    ensure
      krb5.close if krb5
    end
  end
end
