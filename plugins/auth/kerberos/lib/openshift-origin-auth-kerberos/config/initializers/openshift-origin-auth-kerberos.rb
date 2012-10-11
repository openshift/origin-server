require 'openshift-origin-common/config'

Broker::Application.configure do
  conf = OpenShift::Config.new(File.join(OpenShift::Config::PLUGINS_DIR, File.basename(__FILE__, '.rb') + '.conf'))
  defaults = OpenShift::Config.new(File.join(File.dirname(__FILE__), File.basename(__FILE__, '.rb') + '-defaults.conf'))

  config.auth = {
    :salt => conf.get("AUTH_SALT") || defaults.get("AUTH_SALT"),
    :privkeyfile => conf.get("AUTH_PRIVKEYFILE") || defaults.get("AUTH_PRIVKEYFILE"),
    :privkeypass => conf.get("AUTH_PRIVKEYPASS") || defaults.get("AUTH_PRIVKEYPASS"),
    :pubkeyfile  => conf.get("AUTH_PUBKEYFILE") || defaults.get("AUTH_PUBKEYFILE"),
  }
end
