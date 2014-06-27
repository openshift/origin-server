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
    :provider => conf.get("FOG_PROVIDER", "unset"),
    :zone => conf.get("FOG_ZONE", "unset"),
    # Rackspace
    :rackspace_username => conf.get("FOG_RACKSPACE_USERNAME", "unset"),
    :rackspace_api_key => conf.get("FOG_RACKSPACE_API_KEY", "unset"),
    :rackspace_region => conf.get("FOG_RACKSPACE_REGION", "unset")
  }
end
