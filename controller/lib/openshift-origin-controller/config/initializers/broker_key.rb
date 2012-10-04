Broker::Application.configure do
  # If use chooses to inject their auth config before the controller loads we
  # should _not_ overwrite it
  unless config.respond_to? :auth
    config.auth = {
      :salt           => "ClWqe5zKtEW4CJEMyjzQ",
      :privkeyfile    => "/etc/openshift/server_priv.pem",
      :privkeypass    => "",
      :pubkeyfile     => "/etc/openshift/server_pub.pem",
    }
  end
end
