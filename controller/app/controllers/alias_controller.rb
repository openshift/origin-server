class AliasController < BaseController
  include RestModelHelper
  before_filter :get_application
  action_log_tag_resource :alias

  def index
    rest_aliases = @application.aliases.map{ |a| get_rest_alias(a) }
    render_success(:ok, "aliases", rest_aliases, "Listing aliases for application #{@application.name} under domain #{@application.domain_namespace}")
  end

  def show
    id = params[:id].downcase if params[:id].presence

    al1as = @application.aliases.find_by(fqdn: id)
    render_success(:ok, "alias", get_rest_alias(al1as), "Showing alias #{id} for application #{@application.name} under domain #{@application.domain_namespace}")
  end


  def create
    authorize! :create_alias, @application

    server_alias = params[:id].presence || params[:alias].presence
    ssl_certificate = params[:ssl_certificate].presence
    private_key = params[:private_key].presence
    pass_phrase = params[:pass_phrase].presence

    server_alias = server_alias.downcase if server_alias

    if ssl_certificate and @application.capabilities["private_ssl_certificates"] != true
      return render_error(:forbidden, "User is not authorized to add private SSL certificates", 175)
    end

    result = @application.add_alias(server_alias, ssl_certificate, private_key, pass_phrase)

    @analytics_tracker.track_event('alias_add', @domain, @application, {'alias' => server_alias})

    rest_alias = get_rest_alias(@application.aliases.find_by(fqdn: server_alias))
    render_success(:created, "alias", rest_alias, "Added #{server_alias} to application #{@application.name}", result)
  end

  def update
    authorize! :update_alias, @application

    server_alias = params[:id].downcase if params[:id].presence
    ssl_certificate = params[:ssl_certificate].presence
    private_key = params[:private_key].presence
    pass_phrase = params[:pass_phrase].presence

    if ssl_certificate and @application.capabilities["private_ssl_certificates"] != true
      return render_error(:forbidden, "User is not authorized to update private SSL certificates", 175)
    end

    result = @application.update_alias(server_alias, ssl_certificate, private_key, pass_phrase)

    @analytics_tracker.track_event('alias_update', @domain, @application, {'alias' => server_alias})

    al1as = @application.aliases.find_by(fqdn: server_alias)
    rest_alias = get_rest_alias(al1as)
    render_success(:ok, "alias", rest_alias, "Updated #{server_alias} to application #{@application.name}", result)
  end

  def destroy
    authorize! :destroy_alias, @application

    server_alias = params[:id].downcase if params[:id].presence
    result = @application.remove_alias(server_alias)

    @analytics_tracker.track_event('alias_remove', @domain, @application, {'alias' => server_alias})

    status = requested_api_version <= 1.4 ? :no_content : :ok
    render_success(status, nil, nil, "Removed #{server_alias} from application #{@application.name}", result)
  end
end
