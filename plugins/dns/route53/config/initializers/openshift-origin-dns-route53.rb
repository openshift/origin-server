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
    :aws_hosted_zone_id => conf.get("AWS_HOSTED_ZONE_ID", "unset"),
    :aws_access_key_id => conf.get("AWS_ACCESS_KEY_ID", "unset"),
    :aws_access_key => conf.get("AWS_SECRET_KEY", "unset"),
    :ttl => conf.get("TTL", 30) # default record TTL: 30 sec
  }
end
