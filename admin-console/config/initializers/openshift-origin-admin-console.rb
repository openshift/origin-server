require 'openshift-origin-common'

Broker::Application.configure do
  unless config.respond_to? :admin_console # unless already configured...

    # figure out which conf file to use and load it
    name = File.basename(__FILE__, '.rb')
    unless conf_file = ENV['ADMIN_CONSOLE_CONFIG_FILE'] #defined with env var, skip
      base = File.join(OpenShift::Config::PLUGINS_DIR, name)
      if Rails.env.development?
        if File.exist?(dev = base + '-dev.conf')
          conf_file = dev
        else
          Rails.logger.info "Development configuration for #{name} not found. Using production configuration."
        end
      end
      conf_file ||= base + '.conf'
    end
    conf = OpenShift::Config.new(conf_file)

    convert = lambda do |str|
      return nil if str.nil? or str.empty?
      cfg = Hash.new
      str.split(',').each do |tuple|
        profile, value, nothing = tuple.split(':').map(&:strip)
        if value.nil? # no profile: so it's the default
          cfg[:default] = profile.to_i
        elsif nothing.nil?
          cfg[profile] = value.downcase == "none" ? nil : value.to_i
        end # else... we ignore it because there shouldn't be three.
      end
      cfg
    end

    # parse out the various configuration options
    config.admin_console = {
      mount_uri: conf.get("MOUNT_URI", "/admin-console"),
      stats: {
        cache_timeout: eval(conf.get("STATS_CACHE_TIMEOUT", "1.hour")),
        mco_timeout: conf.get("STATS_GATHER_TIMEOUT", 0.5).to_f,
        read_file: conf.get("STATS_FROM_FILE", nil),
      },
      suggest: {
        active_gear_pct: convert.call(conf.get "GEAR_EXPECTED_ACTIVE_PERCENT", "5"),
        gear_up_threshold: convert.call(conf.get "GEAR_UP_THRESHOLD", nil),
        gear_up_size: convert.call(conf.get "GEAR_UP_SIZE", "200"),
        gear_down_threshold: convert.call(conf.get "GEAR_DOWN_THRESHOLD", nil),
      },
      warn: {
        node_active_remaining: conf.get("WARNING_NODE_ACTIVE_REMAINING", 0).to_i,
      },
    }
  end
end
