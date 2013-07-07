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

  config.routing_activemq = {
    :topic => conf.get("ACTIVEMQ_TOPIC", "/topic/routing"),
    :username => conf.get("ACTIVEMQ_USERNAME", "routinginfo"),
    :password => conf.get("ACTIVEMQ_PASSWORD", "routinginfopasswd"),
    :host => conf.get("ACTIVEMQ_HOST", "127.0.0.1"),
    :port => conf.get("ACTIVEMQ_PORT", "61613")
  }
end
