class AuthorizationsController < BaseController

  #
  # Display only non-revoked tokens (includes expired tokens).
  #
  def index
    authorizations = Authorization.for_owner(current_user).not_expired.
                     order_by([:created_at, :desc]).
                     map{ |auth| RestAuthorization.new(auth, get_url, nolinks) }
    render_success(:ok, "authorizations", authorizations, "LIST_AUTHORIZATIONS", 'List authorizations', false, nil, nil, 'IP' => request.remote_ip)
  end

  def create
    scopes = if s = params[:scope] || params[:scopes]
        Scope.list!(s) rescue (
          return render_error(:unprocessable_entity, "One or more of the scopes you provided are not allowed. Valid scopes are #{Scope.describe_all.map(&:first).to_sentence}.",
                              194, "ADD_AUTHORIZATION", "scopes"))
      end
    scopes = Scope.default if scopes.blank?

    max_expires = scopes.maximum_expiration
    expires_in =
      if params[:expires_in].present?
        expires_in = Integer(params[:expires_in]) rescue -1
        (expires_in < 0 || expires_in > max_expires) ? nil : expires_in
      end || scopes.default_expiration

    if params[:reuse]
      token = Authorization.for_owner(current_user).
        matches_details(params[:note], scopes).
        order_by([:created_at, :desc]).
        limit(10).detect{ |i| i.expires_in_seconds > [10.minute.seconds, expires_in / 4].min }
      render_success(:ok, "authorization", RestAuthorization.new(token, get_url, nolinks), "ADD_AUTHORIZATION", "Reused existing") and return if token
    end

    auth = Authorization.create!({
      :expires_in        => expires_in,
      :note              => params[:note],
    }) do |a|
      a.user = current_user
      a.scopes = scopes.to_s
    end
    render_success(:created, "authorization", RestAuthorization.new(auth, get_url, nolinks), "ADD_AUTHORIZATION", "Create authorization", false, nil, nil, 'TOKEN' => auth.token, 'SCOPE' => auth.scopes, 'EXPIRES' => auth.expired_time, 'IP' => request.remote_ip)
  end

  def show
    auth = Authorization.for_owner(current_user).any_of({:token => params[:id].to_s}, {:id => params[:id].to_s}).find_by
    render_success(:ok, "authorization", RestAuthorization.new(auth, get_url, nolinks), "SHOW_AUTHORIZATION", "Display authorization", false, nil, nil, 'TOKEN' => auth.token, 'IP' => request.remote_ip)
  rescue Mongoid::Errors::DocumentNotFound
    render_error(:not_found, "Authorization #{params[:id]} not found", 129, "SHOW_AUTHORIZATION")
  end

  def update
    auth = Authorization.for_owner(current_user).any_of({:token => params[:id].to_s}, {:id => params[:id].to_s}).find_by
    auth.update_attributes!(params.slice(:note))
    render_success(:ok, "authorization", RestAuthorization.new(auth, get_url, nolinks), "UPDATE_AUTHORIZATION", "Change authorization", false, nil, nil, 'TOKEN' => auth.token, 'IP' => request.remote_ip)
  rescue Mongoid::Errors::DocumentNotFound
    render_error(:not_found, "Authorization #{params[:id]} not found", 129, "UPDATE_AUTHORIZATION")
  end

  def destroy
    Authorization.for_owner(current_user).any_of({:token => params[:id].to_s}, {:id => params[:id].to_s}).delete_all
    render_success(:no_content, nil, nil, "DELETE_AUTHORIZATION", "Authorization #{params[:id]} is revoked.", true)
  rescue Mongoid::Errors::DocumentNotFound
    render_error(:no_content, "Authorization #{params[:id]} not found", 129, "DELETE_AUTHORIZATION")
  end

  def destroy_all
    Authorization.for_owner(current_user).delete_all
    render_success(:no_content, nil, nil, "DELETE_AUTHORIZATIONS", "All authorizations for #{@cloud_user.id} are revoked.", true)
  end
end
