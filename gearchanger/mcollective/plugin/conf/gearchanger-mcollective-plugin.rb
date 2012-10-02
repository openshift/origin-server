require 'stickshift-common/config'

Broker::Application.configure do
  conf = StickShift::Config.new(File.join(StickShift::Config::PLUGINS_DIR, 'gearchanger-mcollective-plugin.conf'))

  config.gearchanger = {
    :rpc_options => {
      :disctimeout => (conf.get("MCOLLECTIVE_DISCTIMEOUT") || 5).to_i,
      :timeout => (conf.get("MCOLLECTIVE_TIMEOUT") || 60).to_i,
      :verbose => conf.get_bool("MCOLLECTIVE_VERBOSE"),
      :progress_bar => conf.get_bool("MCOLLECTIVE_PROGRESS_BAR"),
      :filter => {"identity" => [], "fact" => [], "agent" => [], "cf_class" => []},
      :config => conf.get("MCOLLECTIVE_CONFIG")
    },
    :districts => {
      :enabled => conf.get_bool("DISTRICTS_ENABLED"),
      :require_for_app_create => conf.get_bool("DISTRICTS_REQUIRE_FOR_APP_CREATE"),
      :max_capacity => (conf.get("DISTRICTS_MAX_CAPACITY") || 6000).to_i,
      :first_uid => (conf.get("DISTRICTS_FIRST_UID") || 1000).to_i
    },
    :node_profile_enabled => conf.get_bool("NODE_PROFILE_ENABLED")
  }
end
