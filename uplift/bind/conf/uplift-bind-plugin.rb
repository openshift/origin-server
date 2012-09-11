require 'stickshift-common/config'

Broker::Application.configure do
  conf = StickShift::Config.new(File.join(StickShift::Config::PLUGINS_DIR, 'uplift-bind-plugin.conf'))

  config.dns = {
    :server => conf.get("BIND_SERVER"),
    :port => (conf.get("BIND_PORT") || 53).to_i,
    :keyname => conf.get("BIND_KEYNAME"),
    :keyvalue => conf.get("BIND_KEYVALUE"),
    :zone => conf.get("BIND_ZONE")
  }
end
