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

  config.auth[:mongo_host_port] = conf.get("MONGO_HOST_PORT", "localhost:27017")
  config.auth[:mongo_user] = conf.get("MONGO_USER", "openshift")
  config.auth[:mongo_password] = conf.get("MONGO_PASSWORD", "mooo")
  config.auth[:mongo_db] = conf.get("MONGO_DB", "openshift_broker_dev")
  config.auth[:mongo_ssl] = conf.get_bool("MONGO_SSL", "false")
end
