require 'openshift-origin-common'

Broker::Application.configure do
  unless config.respond_to? :msg_broker
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
    
    config.msg_broker = {
      :rpc_options => {
        :disctimeout => conf.get("MCOLLECTIVE_DISCTIMEOUT", "5").to_i,
        :timeout => conf.get("MCOLLECTIVE_TIMEOUT", "60").to_i,
        :verbose => conf.get_bool("MCOLLECTIVE_VERBOSE", "false"),
        :progress_bar => conf.get_bool("MCOLLECTIVE_PROGRESS_BAR", false),
        :filter => {"identity" => [], "fact" => [], "agent" => [], "cf_class" => []},
        :config => conf.get("MCOLLECTIVE_CONFIG", "/etc/mcollective/client.cfg"),
      },
      :districts => {
        :enabled => conf.get_bool("DISTRICTS_ENABLED", "false"),
        :require_for_app_create => conf.get_bool("DISTRICTS_REQUIRE_FOR_APP_CREATE", "false"),
        :max_capacity => conf.get("DISTRICTS_MAX_CAPACITY", "6000").to_i,
        :first_uid => conf.get("DISTRICTS_FIRST_UID", "1000").to_i,
      },
      :node_profile_enabled => conf.get_bool("NODE_PROFILE_ENABLED", "false"),
    }
  end
end
