require 'openshift-origin-common'

Broker::Application.configure do
  conf_file = File.join(OpenShift::Config::PLUGINS_DIR, File.basename(__FILE__, '.rb') + '.conf')
  if Rails.env.development?
    dev_conf_file = File.join(OpenShift::Config::PLUGINS_DIR, File.basename(__FILE__, '.rb') + '-dev.conf')
    if File.exist? dev_conf_file
      conf_file = dev_conf_file
    else
      Rails.logger.info "Development configuration for #{File.basename(__FILE__, '.rb')} not found. Using production configuration."
    end
  end
  conf = OpenShift::Config.new(conf_file)

  config.dns = {
    :server => conf.get("BIND_SERVER", "127.0.0.1"),
    :port => conf.get("BIND_PORT", "53").to_i,
    :zone => conf.get("BIND_ZONE", "example.com"),

    # Authentication information: TSIG or GSS-TSIG (kerberos) but not both
    #
    # TSIG credentials
    :keyname => conf.get("BIND_KEYNAME", nil),
    :keyvalue => conf.get("BIND_KEYVALUE", nil),
    :keyalgorithm => conf.get("BIND_KEYALGORITHM", "HMAC-MD5"),

    # GSS-TSIG (kerberos) credentials
    :krb_principal => conf.get("BIND_KRB_PRINCIPAL", nil),
    :krb_keytab => conf.get("BIND_KRB_KEYTAB", nil),
  }
end
