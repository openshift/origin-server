# @api REST
class DomainsController < BaseController
  include RestModelHelper

  # Retuns list of domains for the current user
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
    return render_error(:bad_request, "Only @self is supported for the 'owner' argument.") if params[:owner] && params[:owner] != "@self"
    render_success(:ok, "domains", Domain.where(owner: current_user).sort_by(&Domain.sort_by_original(current_user)).map{ |d| get_rest_domain(d) })
  end

  # Retuns domain for the current user that match the given parameters.
  # 
  # URL: /domains/:name
  #
  # Action: GET
  # 
  # @param [String] name The name of the domain
  # @return [RestReply<RestDomain>] The requested domain
  def show
    name = params[:name] || params[:id]
    name = name.downcase if name.presence
    get_domain(name)
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
    if requested_api_version <= 1.5
      name = params[:id].downcase if params[:id].presence
      return render_error(:unprocessable_entity, "Namespace is required and cannot be blank.",
                        106, "id") if !name or name.empty?
    else
      name = params[:name].downcase if params[:name].presence
      return render_error(:unprocessable_entity, "Name is required and cannot be blank.",
                        106, "name") if !name or name.empty?
    end
    
    @domain = Domain.new(namespace: name, owner: @cloud_user)
    if not @domain.valid?
      Rails.logger.error "Domain is not valid"
      if requested_api_version <= 1.5
        messages = get_error_messages(@domain, {"namespace" => "id"})
      else
        messages = get_error_messages(@domain, {"namespace" => "name"})
      end
      return render_error(:unprocessable_entity, nil, nil, nil, nil, messages)
    end

    if Domain.where(canonical_namespace: name).count > 0 
      return render_error(:unprocessable_entity, "Namespace '#{name}' is already in use. Please choose another.", 103, "id") if requested_api_version <= 1.5
      return render_error(:unprocessable_entity, "Name '#{name}' is already in use. Please choose another.", 103, "name")
    end

    if Domain.where(owner: @cloud_user).count > 0
      return render_error(:conflict, "There is already a namespace associated with this user", 103, "id") if requested_api_version <= 1.5
      return render_error(:conflict, "There is already a domain associated with this user", 103, "name")
    end

    @domain.save

    render_success(:created, "domain", get_rest_domain(@domain), "Created domain with name #{name}")
  end

  # Create a new domain for the user
  # 
  # URL: /domains/:existing_name
  #
  # Action: PUT
  #
  # @param [String] name The new name for the domain
  # @param [String] existing_name The current name for the domain
  # 
  # @return [RestReply<RestDomain>] The updated domain
  def update
    if requested_api_version <= 1.5
      name = params[:existing_id].downcase if params[:existing_id].presence
      new_name = params[:id].downcase if params[:id].presence
      return render_error(:unprocessable_entity, "Namespace is required and cannot be blank.",106, "id") if !new_name or new_name.empty?
    else
      #TODO FIXME when routing is fixed
      #name = params[:existing_name].downcase if params[:existing_name].presence
      #new_name = params[:name].downcase if params[:name].presence
      name = params[:existing_name] || params[:existing_id]
      name = name.downcase if name.presence
      new_name = params[:name] || params[:id]
      new_name = new_name.downcase if new_name
      return render_error(:unprocessable_entity, "Name is required and cannot be blank.",106, "name") if !new_name or new_name.empty?
    end
    
    @domain = Domain.find_by(owner: @cloud_user, canonical_namespace:  Domain.check_name!(name))
    existing_name = @domain.namespace

    # set the new namespace for validation 
    @domain.namespace = new_name
    if not @domain.valid?
      if requested_api_version <= 1.5
        messages = get_error_messages(@domain, {"namespace" => "id"})
      else
        messages = get_error_messages(@domain, {"namespace" => "name"})
      end
      return render_error(:unprocessable_entity, nil, nil, nil, nil, messages)
    end
    
    #reset the old namespace for use in update_namespace
    @domain.namespace = existing_name
    
    Rails.logger.debug "Updating domain #{@domain.namespace} to #{new_name}"
    result = @domain.update_namespace(new_name)
    @domain.save
    render_success(:ok, "domain", get_rest_domain(@domain), "Updated domain #{name} to #{new_name}", result)
  end

  # Delete a domain for the user. Requires that domain be empty unless 'force' parameter is set.
  # 
  # URL: /domains/:name
  #
  # Action: DELETE
  #
  # @param [Boolean] force If true, broker will delete all applications within the domain and then delete the domain
  def destroy
    name = params[:name] || params[:id]
    name = name.downcase if name.presence
    get_domain(name)
    force = get_bool(params[:force])
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
    status = requested_api_version <= 1.4 ? :no_content : :ok
    render_success(status, nil, nil, "Domain #{name} deleted.", result)
  end

  private

  # Creates a new [RestDomain] or [RestDomain10] based on the requested API version.
  #
  # @param [Domain] domain The Domain object
  # @param [CloudUser] owner of the Domain
  # @return [RestDomain] REST object for API version > 1.0
  # @return [RestDomain10] REST object for API version == 1.0
  def get_rest_domain(domain)
    if requested_api_version == 1.0
      RestDomain10.new(domain, @cloud_user, get_url, nolinks)
    elsif requested_api_version <= 1.5
      RestDomain15.new(domain, @cloud_user, get_url, nolinks)
    else
      RestDomain.new(domain, @cloud_user, get_url, nolinks)
    end
  end
  
  def set_log_tag
    @log_tag = get_log_tag_prepend + "DOMAIN"
  end
end
