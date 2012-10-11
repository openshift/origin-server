require 'openshift-origin-common/config'

Broker::Application.configure do
  conf = OpenShift::Config.new(File.join(OpenShift::Config::PLUGINS_DIR, File.basename(__FILE__, '.rb') + '.conf'))
  defaults = OpenShift::Config.new(File.join(File.dirname(__FILE__), File.basename(__FILE__, '.rb') + '-defaults.conf'))

  config.auth[:trusted_header] = conf.get("TRUSTED_HEADER") || defaults.get("TRUSTED_HEADER")
end
