module OauthHelper
  def valid_redirect_uri?(uri, valid_uris)
    valid_uris.find {|u| uri.start_with?(u) }
  end
end
