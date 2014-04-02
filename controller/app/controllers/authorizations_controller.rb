class AuthorizationsController < BaseController
  #
  # Display only non-revoked tokens (includes expired tokens).
  #
  def index
    authorizations = Authorization.with(consistency: :eventual).for_owner(current_user).not_expired.accessible(current_user).
                     order_by([:created_at, :desc]).
                     map{ |auth| RestAuthorization.new(auth, get_url, nolinks) }
    render_success(:ok, "authorizations", authorizations, 'List authorizations', nil, nil, 'IP' => request.remote_ip)
  end

  def create
    authorize! :create_authorization, current_user

    scopes = if s = params[:scope] || params[:scopes]
        Scope.list!(s) rescue (
          return render_error(:unprocessable_entity, "One or more of the scopes you provided are not allowed. Valid scopes are #{Scope.describe_all.map(&:first).to_sentence}.",
                              1, "scopes"))
      end
    scopes = Scope.default if scopes.blank?

    max_expires = scopes.maximum_expiration
    expires_in =
      if params[:expires_in].present?
        expires_in = Integer(params[:expires_in]) rescue -1
        (expires_in < 0 || expires_in > max_expires) ? nil : expires_in
      end || scopes.default_expiration

    if params[:reuse]
      token = Authorization.for_owner(current_user).accessible(current_user).
        matches_details(params[:note], scopes).
        order_by([:created_at, :desc]).
        limit(10).detect{ |i| i.expires_in_seconds > [10.minute.seconds, expires_in / 4].min }
      render_success(:ok, "authorization", RestAuthorization.new(token, get_url, nolinks), "Reused existing") and return if token
    end

    auth = Authorization.create!({
      :expires_in        => expires_in,
      :note              => params[:note],
    }) do |a|
      a.user = current_user
      a.scopes = scopes.to_s
    end

    @analytics_tracker.track_user_event("authorization_add", current_user)

    render_success(:created, "authorization", RestAuthorization.new(auth, get_url, nolinks), "Create authorization", nil, nil, 'TOKEN' => auth.token, 'SCOPE' => auth.scopes, 'EXPIRES' => auth.expired_time, 'IP' => request.remote_ip)
  end

  def show
    auth = Authorization.with(consistency: :eventual).for_owner(current_user).any_of({:token => params[:id].to_s}, {:id => params[:id].to_s}).accessible(current_user).find_by
    render_success(:ok, "authorization", RestAuthorization.new(auth, get_url, nolinks), "Display authorization", nil, nil, 'TOKEN' => auth.token, 'IP' => request.remote_ip)
  end

  def update
    authorize! :update_authorization, current_user
    auth = Authorization.for_owner(current_user).any_of({:token => params[:id].to_s}, {:id => params[:id].to_s}).accessible(current_user).find_by
    auth.update_attributes!(params.slice(:note))
    render_success(:ok, "authorization", RestAuthorization.new(auth, get_url, nolinks), "Change authorization", nil, nil, 'TOKEN' => auth.token, 'IP' => request.remote_ip)
  end

  def destroy
    authorize! :destroy_authorization, current_user
    Authorization.for_owner(current_user).any_of({:token => params[:id].to_s}, {:id => params[:id].to_s}).accessible(current_user).delete_all
    status = requested_api_version <= 1.4 ? :no_content : :ok
    render_success(status, nil, nil, "Authorization #{params[:id]} is revoked.")
  rescue Mongoid::Errors::DocumentNotFound
    render_error(:ok, "Authorization #{params[:id]} not found", 129)
  end

  def destroy_all
    authorize! :destroy_authorization, current_user
    authorizations = Authorization.for_owner(current_user).accessible(current_user)
    if (s = params[:scope]).present?
      authorizations.select {|a| a.scopes_list.include?(s) }.map(&:delete)
      msg = "All authorizations for #{@cloud_user.id} with scope #{s} are revoked."
    else
      authorizations.delete_all
      msg = "All authorizations for #{@cloud_user.id} are revoked."
    end
    status = requested_api_version <= 1.4 ? :no_content : :ok
    render_success(status, nil, nil, msg)
  end
end
