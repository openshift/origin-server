Broker::Application.configure do
  config.auth[:trusted_header] = "REMOTE_USER"
end
