require 'openshift-origin-common/config'

Broker::Application.configure do
  unless config.respond_to? :msg_broker
    conf = OpenShift::Config.new(File.join(OpenShift::Config::PLUGINS_DIR, File.basename(__FILE__, '.rb') + '.conf'))
    defaults = OpenShift::Config.new(File.join(File.dirname(__FILE__), File.basename(__FILE__, '.rb') + '-defaults.conf'))

    config.msg_broker = {
      :rpc_options => {
        :disctimeout => (conf.get("MCOLLECTIVE_DISCTIMEOUT") || defaults.get("MCOLLECTIVE_DISCTIMEOUT")).to_i,
        :timeout => (conf.get("MCOLLECTIVE_TIMEOUT") || defaults.get("MCOLLECTIVE_TIMEOUT")).to_i,
        :verbose => conf.get_bool("MCOLLECTIVE_VERBOSE") || defaults.get_bool("MCOLLECTIVE_VERBOSE"),
        :progress_bar => conf.get_bool("MCOLLECTIVE_PROGRESS_BAR") || defaults.get_bool("MCOLLECTIVE_PROGRESS_BAR"),
        :filter => {"identity" => [], "fact" => [], "agent" => [], "cf_class" => []},
        :config => conf.get("MCOLLECTIVE_CONFIG") || defaults.get("MCOLLECTIVE_CONFIG")
      },
      :districts => {
        :enabled => conf.get_bool("DISTRICTS_ENABLED") || defaults.get_bool("DISTRICTS_ENABLED"),
        :require_for_app_create => conf.get_bool("DISTRICTS_REQUIRE_FOR_APP_CREATE") || defaults.get_bool("DISTRICTS_REQUIRE_FOR_APP_CREATE"),
        :max_capacity => (conf.get("DISTRICTS_MAX_CAPACITY") || defaults.get("DISTRICTS_MAX_CAPACITY")).to_i,
        :first_uid => (conf.get("DISTRICTS_FIRST_UID") || defaults.get("DISTRICTS_FIRST_UID")).to_i
      },
      :node_profile_enabled => conf.get_bool("NODE_PROFILE_ENABLED") || defaults.get("NODE_PROFILE_ENABLED")
    }
  end
end
