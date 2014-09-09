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

  config.gear_placement = {
    :confkey1 => conf.get("CONFKEY1", "value1"),
    :confkey2 => conf.get("CONFKEY2", "value2"),
    :confkey3 => conf.get("CONFKEY3", "value3")
  }
end
