# @api REST
class DomainsController < BaseController

  # Retuns list of domains for the current user
  # 
  # URL: /domains
  #
  # Action: GET
  # 
  # @return [RestReply<Array<RestDomain>>] List of domains
  def index
    rest_domains = Array.new
    Rails.logger.debug "Getting domains for user #{@cloud_user.login}"
    domains = Domain.where(owner: @cloud_user)
    domains.each do |domain|
      rest_domains.push get_rest_domain(domain, @cloud_user)
    end
    render_success(:ok, "domains", rest_domains, "LIST_DOMAINS")
  end

  # Retuns domain for the current user that match the given parameters.
  # 
  # URL: /domains/:id
  #
  # Action: GET
  # 
  # @param [String] id The namespace of the domain
  # @return [RestReply<RestDomain>] The requested domain
  def show
    id = params[:id]
    Rails.logger.debug "Getting domain #{id}"

    # validate the domain name using regex to avoid a mongo call, if it is malformed
    if id !~ Domain::DOMAIN_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "Domain #{id} not found.", 127, "SHOW_DOMAIN")
    end

    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: id.downcase)
      @domain_name = domain.namespace
      return render_success(:ok, "domain", get_rest_domain(domain, @cloud_user), "SHOW_DOMAIN", "Found domain #{id}")
    rescue Mongoid::Errors::DocumentNotFound
      render_error(:not_found, "Domain #{id} not found.", 127, "SHOW_DOMAIN")
    end
  end

  # Create a new domain for the user
  # 
  # URL: /domains
  #
  # Action: POST
  #
  # @param [String] id The namespace for the domain
  # 
  # @return [RestReply<RestDomain>] The new domain
  def create
    namespace = params[:id]
    Rails.logger.debug "Creating domain with namespace #{namespace}"

    return render_error(:unprocessable_entity, "Namespace is required and cannot be blank.",
                        106, "ADD_DOMAIN", "id") if !namespace or namespace.empty?

    domain = Domain.new(namespace: namespace, owner: @cloud_user)
    if not domain.valid?
      Rails.logger.error "Domain is not valid"
      messages = get_error_messages(domain, {"namespace" => "id"})
      return render_error(:unprocessable_entity, nil, nil, "ADD_DOMAIN", nil, nil, messages)
    end

    if Domain.where(canonical_namespace: namespace.downcase).count > 0
      return render_error(:unprocessable_entity, "Namespace '#{namespace}' is already in use. Please choose another.", 103, "ADD_DOMAIN", "id")
    end

    if Domain.where(owner: @cloud_user).count > 0
      return render_error(:conflict, "There is already a namespace associated with this user", 103, "ADD_DOMAIN", "id")
    end

    @domain_name = domain.namespace
    begin
      domain.save
    rescue Exception => e
      return render_exception(e, "ADD_DOMAIN") 
    end

    render_success(:created, "domain", get_rest_domain(domain, @cloud_user), "ADD_DOMAIN", "Created domain with namespace #{namespace}")
  end

  # Create a new domain for the user
  # 
  # URL: /domains/:existing_id
  #
  # Action: PUT
  #
  # @param [String] id The new namespace for the domain
  # @param [String] existing_id The current namespace for the domain
  # 
  # @return [RestReply<RestDomain>] The updated domain
  def update
    id = params[:existing_id]
    new_namespace = params[:id]
    
    return render_error(:unprocessable_entity, "Namespace is required and cannot be blank.",
                        106, "UPDATE_DOMAIN", "id") if !new_namespace or new_namespace.empty?

    # validate the domain name using regex to avoid a mongo call, if it is malformed
    if id !~ Domain::DOMAIN_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "Domain #{id} not found", 127, "UPDATE_DOMAIN")
    end

    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: id.downcase)
      existing_namespace = domain.namespace
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain '#{id}' not found", 127, "UPDATE_DOMAIN")
    end
    
    if Application.with(consistency: :strong).where(domain_id: domain._id).count > 0
      return render_error(:unprocessable_entity, "Domain contains applications. Delete applications first before changing the domain namespace.", 128)
    end
    
    if Domain.where(canonical_namespace: new_namespace.downcase).count > 0
      return render_error(:unprocessable_entity, "Namespace '#{new_namespace}' is already in use. Please choose another.", 103, "UPDATE_DOMAIN", "id")
    end

    # set the new namespace for validation 
    domain.namespace = new_namespace
    if not domain.valid?
      messages = get_error_messages(domain, {"namespace" => "id"})
      return render_error(:unprocessable_entity, nil, nil, "UPDATE_DOMAIN", nil, nil, messages)
    end
    
    #reset the old namespace for use in update_namespace
    domain.namespace = existing_namespace
    
    @domain_name = domain.namespace
    Rails.logger.debug "Updating domain #{domain.namespace} to #{new_namespace}"

    begin
      domain.update_namespace(new_namespace)
      domain.save
    rescue Exception => e
      return render_exception(e, "UPDATE_DOMAIN") 
    end
    
    render_success(:ok, "domain", get_rest_domain(domain, @cloud_user), "UPDATE_DOMAIN", "Updated domain #{id} to #{new_namespace}")
  end

  # Delete a domain for the user. Requires that domain be empty unless 'force' parameter is set.
  # 
  # URL: /domains/:id
  #
  # Action: DELETE
  #
  # @param [Boolean] force If true, broker will destroy all application within the domain and then destroy the domain
  def destroy
    id = params[:id]
    force = get_bool(params[:force])
    
    # validate the domain name using regex to avoid a mongo call, if it is malformed
    if id !~ Domain::DOMAIN_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "Domain #{id} not found", 127, "DELETE_DOMAIN")
    end

    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: id.downcase)
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{id} not found", 127, "DELETE_DOMAIN")
    end

    if force
      apps = Application.with(consistency: :strong).where(domain_id: domain._id)
      while apps.count > 0
        apps.each do |app|
          app.destroy_app
        end
        apps = Application.with(consistency: :strong).where(domain_id: domain._id)
      end
    elsif Application.with(consistency: :strong).where(domain_id: domain._id).count > 0
      if requested_api_version <= 1.3
        return render_error(:bad_request, "Domain contains applications. Delete applications first or set force to true.", 128, "DELETE_DOMAIN")
      else
        return render_error(:unprocessable_entity, "Domain contains applications. Delete applications first or set force to true.", 128, "DELETE_DOMAIN")
      end
    end

    @domain_name = domain.namespace
    begin
      # reload the domain so that MongoId does not see any applications
      domain.with(consistency: :strong).reload
      domain.delete
      render_success(:no_content, nil, nil, "DELETE_DOMAIN", "Domain #{id} deleted.", true)
    rescue Exception => e
      return render_exception(e, "DELETE_DOMAIN") 
    end
  end

  private

  # Creates a new [RestDomain] or [RestDomain10] based on the requested API version.
  #
  # @param [Domain] domain The Domain object
  # @param [CloudUser] owner of the Domain
  # @return [RestDomain] REST object for API version > 1.0
  # @return [RestDomain10] REST object for API version == 1.0
  def get_rest_domain(domain, owner)
    if requested_api_version == 1.0
      RestDomain10.new(domain, owner, get_url, nolinks)
    else
      RestDomain.new(domain, owner, get_url, nolinks)
    end
  end
end
