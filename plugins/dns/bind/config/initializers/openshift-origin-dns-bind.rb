require 'openshift-origin-common'

# Add DNS plugin configuration information to the Rails::application.config
# object
#
# @see OpenShift::BindPlugin
#
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
    :keyname => conf.get("BIND_KEYNAME", "example.com"),
    :keyvalue => conf.get("BIND_KEYVALUE", "base64-encoded key, most likely from /var/named/example.com.key."),
    :zone => conf.get("BIND_ZONE", "example.com")
  }
end
