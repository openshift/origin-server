class Scope::OauthAccessToken < Scope::Simple
  # Allows a client to exchange an OAuth code for an access token

  def allows_action?(controller)
    controller.is_a?(OauthController) && controller.action_name == 'access_token'
  end

  # Override description to nil to avoid displaying in API help
  def describe
    nil
  end

  def authorize_action?(permission, resource, other_resources, user)
    permission == :create_oauth_access_token && resource.is_a?(CloudUser)
  end

end
