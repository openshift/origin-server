require 'openshift-origin-common'

Broker::Application.configure do
  conf_file = File.join(OpenShift::Config::PLUGINS_DIR, File.basename(__FILE__, 
'.rb') + '.conf')
  if Rails.env.development?
    dev_conf_file = File.join(OpenShift::Config::PLUGINS_DIR, File.basename(__FI
LE__, '.rb') + '-dev.conf')
    if File.exist? dev_conf_file
      conf_file = dev_conf_file
    else
      Rails.logger.info "Development configuration for #{File.basename(__FILE__,
 '.rb')} not found. Using production configuration."
    end
  end
  conf = OpenShift::Config.new(conf_file)

  config.dns = {
    # for checking 
    :server => conf.get("DNSMASQ_SERVER", "127.0.0.1"),
    :port => conf.get("DNSMASQ_PORT", "53").to_i,
    :zone => conf.get("DNSMASQ_ZONE", "example.com"),
    :config_file = conf.get("DNSMASQ_CONF", "/etc/dnsmasq.conf"),
    :hosts_dir = conf.get("DNSMASQ_HOSTS_DIR", "/etc/dnsmasq.d")    
  }
end
