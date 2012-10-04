require 'stickshift-common/config'

Broker::Application.configure do
  conf = StickShift::Config.new(File.join(StickShift::Config::PLUGINS_DIR, File.basename(__FILE__, '.rb') + '.conf'))
  defaults = StickShift::Config.new(File.join(File.dirname(__FILE__), File.basename(__FILE__, '.rb') + '-defaults.conf'))

  config.dns = {
    :server => conf.get("BIND_SERVER") || defaults.get("BIND_SERVER"),
    :port => (conf.get("BIND_PORT") || defaults.get("BIND_PORT")).to_i,
    :keyname => conf.get("BIND_KEYNAME") || defaults.get("BIND_KEYNAME"),
    :keyvalue => conf.get("BIND_KEYVALUE") || defaults.get("BIND_KEYVALUE"),
    :zone => conf.get("BIND_ZONE") || defaults.get("BIND_ZONE")
  }
end
