Broker::Application.configure do
  config.auth = {
    :salt           => "ClWqe5zKtEW4CJEMyjzQ",
    :privkeyfile    => "/etc/stickshift/server_priv.pem",
    :privkeypass    => "",
    :pubkeyfile     => "/etc/stickshift/server_pub.pem",
  }
end
