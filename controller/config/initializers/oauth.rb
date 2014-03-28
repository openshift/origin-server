Rails.application.config.tap do |config|

  config.oauth_enabled = true
  config.oauth_clients = HashWithIndifferentAccess.new

  # config.oauth_clients[:client_id] = {
  #   # Authorize and access token requests must pass this client id
  #   :id => 'client_id',
  #
  #   # Access token requests must pass one of these client secrets
  #   :secrets => ['client_secret1', 'client_secret2'],
  #
  #   # Client display name
  #   :name => 'Client Display Name',
  #
  #   # Authorize requests must redirect to a subpath of one of these uris
  #   :redirect_uris => ['https://www.example.com/1', 'https://www.example.com/2'],
  #
  #   # Default scopes for client
  #   :scopes => 'userinfo read',
  #
  #   # Adds 'sso' scope, tokens granted to this client will be deleted on logout
  #   :is_sso => true
  # }


end
