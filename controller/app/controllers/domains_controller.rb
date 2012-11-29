class DomainsController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version

  # GET /domains
  def index
    domains = Array.new
    Rails.logger.debug "Getting domains for user #{@cloud_user.login}"
    Rails.logger.debug @cloud_user.domains
    @cloud_user.domains.each do |domain|
      if $requested_api_version >= 1.3
          domains.push(RestDomain.new(domain, get_url, nolinks))
      else
          domains.push(RestDomain10.new(domain, get_url, nolinks))
      end
    end
    render_success(:ok, "domains", domains, "LIST_DOMAINS")
  end

  # GET /domains/<id>
  def show
    id = params[:id]
    Rails.logger.debug "Getting domain #{id}"

    domain = Domain.get(@cloud_user, id)
    if domain and domain.hasAccess?(@cloud_user)
      @domain = domain.namespace
      if $requested_api_version >= 1.3
        domain = RestDomain.new(domain, get_url, nolinks)
      else
        domain = RestDomain10.new(domain, get_url, nolinks)
      end
      return render_success(:ok, "domain", domain, "SHOW_DOMAIN", "Found domain #{id}")
    end
    render_error(:not_found, "Domain #{id} not found.", 127, "SHOW_DOMAIN")
  end

  # POST /domains
  def create
    namespace = params[:id]
    Rails.logger.debug "Creating domain with namespace #{namespace}"

    domain = Domain.new(namespace, @cloud_user)
    if not domain.valid?
      Rails.logger.error "Domain is not valid"
      messages = get_error_messages(domain, "namespace", "id")
      return render_error(:unprocessable_entity, nil, nil, "ADD_DOMAIN", nil, nil, messages)
    end

    begin
      dom_available = Domain.namespace_available?(namespace)
    rescue Exception => e
      return render_exception(e, "ADD_DOMAIN") 
    end

    return render_error(:unprocessable_entity, "Namespace '#{namespace}' is already in use. Please choose another.", 103, "ADD_DOMAIN", "id") if !dom_available 

    return render_error(:conflict, "Domain already exists for user. Update the domain to modify.", 158, "ADD_DOMAIN") if !@cloud_user.domains.empty?

    @domain = namespace
    begin
      domain.save
    rescue Exception => e
      return render_exception(e, "ADD_DOMAIN") 
    end

    if $requested_api_version >= 1.3
      domain = RestDomain.new(domain, get_url, nolinks)
    else
      domain = RestDomain10.new(domain, get_url, nolinks)
    end
    render_success(:created, "domain", domain, "ADD_DOMAIN", "Created domain with namespace #{namespace}", true)
  end

  # PUT /domains/<existing_id>
  def update
    id = params[:existing_id]
    new_namespace = params[:id]
    domain = Domain.get(@cloud_user, id)

    new_domain = Domain.new(new_namespace, @cloud_user)
    if not new_domain.valid?
      messages = get_error_messages(new_domain, "namespace", "id")
      return render_format_error(:unprocessable_entity, nil, nil, "UPDATE_DOMAIN", nil, nil, messages)
    end
    return render_format_error(:not_found, "Domain '#{id}' not found", 127, 
                               "UPDATE_DOMAIN") if !domain || !domain.hasAccess?(@cloud_user)

    return render_format_error(:forbidden, "User does not have permission to modify domain '#{id}'",
                               132, "UPDATE_DOMAIN") if domain && !domain.hasFullAccess?(@cloud_user)

    Rails.logger.debug "Updating domain #{domain.namespace} to #{new_namespace}"
    begin
      dom_available = Domain.namespace_available?(new_namespace)
    rescue Exception => e
      return render_format_exception(e, "UPDATE_DOMAIN") 
    end

    return render_format_error(:unprocessable_entity, "Namespace '#{new_namespace}' already in use. Please choose another.",
                               103, "UPDATE_DOMAIN", "id") if !dom_available

    domain.namespace = new_namespace
    if domain.invalid?
      messages = get_error_messages(domain, "namespace", "id")
      return render_format_error(:unprocessable_entity, nil, nil, "UPDATE_DOMAIN", nil, nil, messages)
    end

    @domain = id
    begin
      domain.save
    rescue Exception => e
      return render_format_exception(e, "UPDATE_DOMAIN") 
    end

    @cloud_user = CloudUser.find(@login)
    if $requested_api_version >= 1.3
      domain = RestDomain.new(domain, get_url, nolinks)
    else
      domain = RestDomain10.new(domain, get_url, nolinks)
    end
    render_format_success(:ok, "domain", domain, "UPDATE_DOMAIN", "Updated domain #{id} to #{new_namespace}")
  end

  # DELETE /domains/<id>
  def destroy
    id = params[:id]
    force = get_bool(params[:force])

    domain = Domain.get(@cloud_user, id)
    return render_format_error(:not_found, "Domain #{id} not found", 127,
                               "DELETE_DOMAIN") if !domain || !domain.hasAccess?(@cloud_user)

    return render_format_error(:forbidden, "User does not have permission to delete domain '#{id}'",
                               132, "DELETE_DOMAIN") if domain && !domain.hasFullAccess?(@cloud_user)

    if force
      Rails.logger.debug "Force deleting domain #{id}"
      @cloud_user.applications.each do |app|
        app.cleanup_and_delete if app.domain.uuid == domain.uuid
      end if @cloud_user.applications
    else
      @cloud_user.applications.each do |app|
        return render_format_error(:bad_request, "Domain contains applications. Delete applications first or set force to true.", 
                                   128, "DELETE_DOMAIN") if app.domain.uuid == domain.uuid
      end if @cloud_user.applications
    end

    @domain = id
    begin
      domain.delete
      render_format_success(:no_content, nil, nil, "DELETE_DOMAIN", "Domain #{id} deleted.", true)
    rescue Exception => e
      return render_format_exception(e, "DELETE_DOMAIN") 
    end
  end
end
