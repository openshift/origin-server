module Console::BrokerHelper
  # RestApi.site.host comes from the value in console.conf for BROKER_URL.
  # Currently if using the remote-user auth plugin we only allow the broker and
  # console to run on the same host and to communicate over the loopback
  # interface.  We don't 127.0.0.1 or 'localhost' to show up in the UI though.
  #
  # As part of BZ893172 we will add a new configuration value and improve the
  # remote-user auth plugin
  def broker_host
    ['127.0.0.1', 'localhost'].include?(RestApi.site.host) ? request.host : RestApi.site.host
  end
end
