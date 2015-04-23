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

  config.sso_activemq = {
    :destination => conf.get("ACTIVEMQ_DESTINATION", conf.get("ACTIVEMQ_TOPIC", "/topic/sso")),
    :hosts => conf.get("ACTIVEMQ_HOST", "127.0.0.1").split(',').map do |hp|
      hp.split(":").instance_eval do |h,p|
        {
          :host => h,
          # Originally, ACTIVEMQ_HOST allowed specifying only one host, with
          # the port specified separately in ACTIVEMQ_PORT.
          :port => p || conf.get("ACTIVEMQ_PORT", "61613"),
        }
      end
    end,
    :username => conf.get("ACTIVEMQ_USERNAME", "ssoinfo"),
    :password => conf.get("ACTIVEMQ_PASSWORD", "ssoinfopasswd"),
    :debug => conf.get_bool("ACTIVEMQ_DEBUG", "false"),
    :mcollective_conf => conf.get("MCOLLECTIVE_CONFIG"),
  }
end
