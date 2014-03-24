class OauthController < ConsoleController

  def authorize
    # Pass through the allowed parameters to the broker
    uri = URI("#{RestApi::Base.prefix}oauth/authorize")
    uri.query = params.slice(:client_id, :redirect_uri, :state, :response_type).to_query

    # Make the broker call as the authorized user
    connection = RestApi::Base.connection(:as => current_user)
    connection.get(uri.to_s)

    # Should return a 302 redirect or an error. If we get a regular response, that's a problem.
    raise UnexpectedOAuthResponse.new("An unexpected OAuth response (non-302, non-error) was received")

  rescue UnexpectedOAuthResponse => e
    log_error(e)
    @message = "OAuth Error: Unexpected response"
    render :error

  rescue ActiveResource::Redirection => e
    # Handles success case which redirects with a temporary authorization code
    # Handles failure cases which redirect to return errors to the OAuth client
    redirect_to e.response.header['location']

  rescue ActiveResource::BadRequest => e
    begin
      # Handles error cases which are supposed to alert the user of bad OAuth requests
      json = JSON.parse(e.response.body)
      raise e unless (details = json['error_description'] || json['error'])
      @message = "OAuth Error: #{details}"
      render :error
    rescue
      # If we didn't get an error format we recognize, raise the original exception
      raise e
    end
  end

  private
    class UnexpectedOAuthResponse < Exception
    end

end
