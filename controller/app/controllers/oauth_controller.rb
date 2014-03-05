require 'base64'

class OauthController < BaseController
  include OauthHelper

  def authorize
    authorize! :create_authorization, current_user

    client_id = params[:client_id].to_s
    redirect_uri = params[:redirect_uri].to_s
    response_type = params[:response_type].to_s

    # Validate params
    return render_missing_param(:client_id)     if client_id.blank?
    return render_missing_param(:redirect_uri)  if redirect_uri.blank?
    return render_missing_param(:response_type) if response_type.blank?
    return render_oauth_error("unsupported_response_type", "response_type must be 'code'", :bad_request) if response_type != "code"

    # Validate client and redirect uri
    client = Rails.configuration.oauth_clients[client_id]
    return render_oauth_error("invalid_client") if client.blank?
    return render_oauth_error("invalid_request", "redirect_uri is not allowed for this client", :bad_request) unless valid_redirect_uri?(redirect_uri, client[:redirect_uris])
    
    # Create token with oauthaccesstoken scope
    scopes = Scope.list!("oauthaccesstoken")
    access_token = Authorization.create!({
      :expires_in => scopes.default_expiration,
      :note       => "OAuth code for #{client[:name]}"
    }) do |a|
      a.user = current_user
      a.scopes = scopes.to_s
      a.oauth_client_id = client[:id]
    end

    # Build redirect URI
    uri = URI(redirect_uri)
    return_params = {:code => access_token.token}
    return_params[:state] = params[:state] if params[:state]
    uri.query = return_params.to_query

    # Send redirect
    redirect_to uri.to_s
  end



  def access_token
    authorize! :create_oauth_access_token, current_user

    # Require calls to use POST method per rfc6749, section 2.3.1
    return render_oauth_error("invalid_request", "POST method required", :bad_request) unless request.post?

    code = params[:code].to_s
    grant_type = params[:grant_type].to_s
    if request.authorization.to_s[/^Basic (.*)/i]
      # Support providing the client_id and client_secret via Basic auth, per rfc6749, section 2.3.1
      client_id,client_secret = Base64.decode64($1.strip).split(':', 2) rescue nil
    else
      # Allow providing the client_id and client_secret via body params
      client_id = params[:client_id].to_s
      client_secret = params[:client_secret].to_s
    end

    # Validate params
    return render_missing_param(:client_id)     if client_id.blank?
    return render_missing_param(:client_secret) if client_secret.blank?
    return render_missing_param(:code)          if code.blank?
    return render_missing_param(:grant_type)    if grant_type.blank?
    return render_oauth_error("unsupported_grant_type", "grant_type must be 'authorization_code'", :bad_request) if grant_type != "authorization_code"

    # Validate client and secret
    client = Rails.configuration.oauth_clients[client_id]
    return render_oauth_error("invalid_client") if client.blank?
    return render_oauth_error("unauthorized_client", "client_secret is not valid", :unauthorized) unless client[:secrets].include?(client_secret)


    # Get the temporary authorization and verify it is for this client
    temp_auth = Authorization.authenticate(code)
    return render_oauth_error("unauthorized_client", "code is not valid", :unauthorized) if temp_auth.blank?
    return render_oauth_error("unauthorized_client", "code is not valid", :unauthorized) if temp_auth.oauth_client_id != client_id

    # Create a new authorization with the desired scopes
    # Hard-code configured scopes in client config for now
    scopes = Scope.list!(client[:scopes])
    scopes << Scope.for('sso') if client[:is_sso]
    new_auth = Authorization.create!({
      :expires_in => scopes.default_expiration,
      :note       => "OAuth access token for #{client[:name]}"
    }) do |a|
      a.user = current_user
      a.scopes = scopes.to_s
      a.oauth_client_id = client[:id]
    end

    # Delete the temporary authorization
    temp_auth.delete

    # Send the new access token to the client
    response_data = {
      :access_token => new_auth.token,
      :expires_in => new_auth.expires_in,
      :token_type => "Bearer"
    }

    respond_to do |format|
      format.json { render :json => response_data and return }
      format.any { render :text => response_data.to_query and return }
    end
  end

  protected
    def bearer_token_override(original_token=nil)
      if action_name == "access_token"
        params[:code]
      else
        original_token
      end
    end

  private
    def render_missing_param(param_name)
      render_oauth_error("invalid_request", "#{param_name} is required", :bad_request)
    end

    def render_oauth_error(code, description=nil, status=:bad_request)
      response_data = {:error => code}
      response_data[:error_description] = description if description.present?
      respond_to do |format|
        format.json { render :json => response_data, :status => status and return }
        format.any { render :text => response_data.to_query, :status => status and return }
      end
    end

end
