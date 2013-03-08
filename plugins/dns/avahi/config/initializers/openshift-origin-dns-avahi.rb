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
    :server => conf.get("MDNS_SERVER", "127.0.0.1"),
    :port => conf.get("MDNS_PORT", "8053").to_i,
    :keyname => conf.get("MDNS_KEYNAME", "openshift.local"),
    :keyvalue => conf.get("MDNS_KEYVALUE", ""),
    :zone => conf.get("MDNS_ZONE", "openshift.local")
  }
end
