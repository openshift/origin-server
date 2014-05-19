# @api REST
class DomainsController < BaseController
  include RestModelHelper

  # Returns list of domains for the current user
  #
  # URL: /domains
  #
  # Action: GET
  #
  # @param [String] owner The id of an owner to show the domains for.  Special values: 
  #                         @self - returns the current user.
  #
  # @return [RestReply<Array<RestDomain>>] List of domains
  def index
    domains =
      case params[:owner]
      when "@self" then Domain.accessible(current_user).where(owner: current_user)
      when nil     then Domain.accessible(current_user)
      else return render_error(:bad_request, "Only @self is supported for the 'owner' argument.") 
      end

    if_included(:application_info, {}){ domains = domains.with_gear_counts }

    # Always include domain capability info, which we get from the owner
    domains = Domain.with_owner_info(domains)

    render_success(:ok, "domains", domains.sort_by(&Domain.sort_by_original(current_user)).map{ |d| get_rest_domain(d) })
  end

  # Returns domain for the current user that match the given parameters.
  #
  # URL: /domain/:name
  #
  # Action: GET
  #
  # @param [String] name The name of the domain
  # @return [RestReply<RestDomain>] The requested domain
  def show
    get_domain(params[:name] || params[:id])

    if_included(:application_info){ @domain.with_gear_counts }

    # Always include domain capability info, which we get from the owner
    @domain = @domain.with_owner_info

    return render_success(:ok, "domain", get_rest_domain(@domain), "Found domain #{@domain.namespace}") if @domain
  end

  # Create a new domain for the user
  #
  # URL: /domains
  #
  # Action: POST
  #
  # @param [String] name The name for the domain
  #
  # @return [RestReply<RestDomain>] The new domain
  def create
    authorize! :create_domain, current_user

    namespace = (params[:name] || params[:id] || params[:namespace] || '').downcase
    if OpenShift::ApplicationContainerProxy.blacklisted? namespace
      return render_error(:forbidden, "Namespace is not allowed.  Please choose another.", 106)
    end

    allowed_domains = nil
    allowed_domains = 1 if requested_api_version < 1.2
    allowed_gear_sizes = Array(params[:allowed_gear_sizes]) if params.has_key? :allowed_gear_sizes

    @domain = Domain.create!(namespace: namespace, owner: current_user, allowed_gear_sizes: allowed_gear_sizes, _allowed_domains: allowed_domains)

    @analytics_tracker.track_event('domain_create', @domain, nil)

    render_success(:created, "domain", get_rest_domain(@domain), "Created domain with name #{@domain.namespace}")
  end

  # Create a new domain for the user
  #
  # URL: /domain/:existing_name
  #
  # Action: PUT
  #
  # @param [String] name The new name for the domain
  # @param [String] existing_name The current name for the domain
  #
  # @return [RestReply<RestDomain>] The updated domain
  def update
    id = params[:existing_name].presence || params[:existing_id].presence

    new_namespace = params[:name] || params[:id]
    if OpenShift::ApplicationContainerProxy.blacklisted? new_namespace
      return render_error(:forbidden, "Namespace is not allowed.  Please choose another.", 106)
    end

    domain = Domain.accessible(current_user).find_by(canonical_namespace: Domain.check_name!(id).downcase)

    messages = []

    if !new_namespace.nil?
      domain.namespace = new_namespace.downcase
      if domain.namespace_changed?
        authorize!(:change_namespace, domain)
        messages << "Changed namespace to '#{domain.namespace}'."
      end
    end

    if params.has_key? :allowed_gear_sizes
      domain.allowed_gear_sizes = Array(params[:allowed_gear_sizes]).map(&:presence).compact
      if domain.allowed_gear_sizes_changed?
        authorize!(:change_gear_sizes, domain)
        messages << "Updated allowed gear sizes."
      end
    end

    return render_error(:unprocessable_entity, "No changes specified to the domain.", 133) unless domain.changed?

    domain.save!

    @analytics_tracker.track_event('domain_update', domain, nil)

    render_success(:ok, "domain", get_rest_domain(domain), messages.join(" "), domain)
  end

  # Delete a domain for the user. Requires that domain be empty unless 'force' parameter is set.
  #
  # URL: /domain/:name
  #
  # Action: DELETE
  #
  # @param [Boolean] force If true, broker will delete all applications within the domain and then delete the domain
  def destroy
    name = params[:name] || params[:id]
    name = name.downcase if name.presence
    get_domain(name)
    force = get_bool(params[:force])

    authorize! :destroy, @domain

    if force
      while (apps = Application.where(domain_id: @domain._id)).present?
        apps.each(&:destroy_app)
      end
    elsif Application.where(domain_id: @domain._id).present?
      if requested_api_version <= 1.3
        return render_error(:bad_request, "Domain contains applications. Delete applications first or set force to true.", 128)
      else
        return render_error(:unprocessable_entity, "Domain contains applications. Delete applications first or set force to true.", 128)
      end
    end
    # reload the domain so that MongoId does not see any applications
    @domain.reload
    result = @domain.delete

    @analytics_tracker.track_event('domain_delete', @domain, nil)

    status = requested_api_version <= 1.4 ? :no_content : :ok
    render_success(status, nil, nil, "Domain #{name} deleted.", result)
  end

  private
    include ActionView::Helpers::TextHelper

    def set_log_tag
      @log_tag = get_log_tag_prepend + "DOMAIN"
    end
end
