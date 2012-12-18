class DomainsController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version

  # GET /domains
  def index
    rest_domains = Array.new
    Rails.logger.debug "Getting domains for user #{@cloud_user.login}"
    domains = Domain.where(owner: @cloud_user)
    Rails.logger.debug domains
    domains.each do |domain|
      rest_domains.push get_rest_domain(domain)
    end
    render_success(:ok, "domains", rest_domains, "LIST_DOMAINS")
  end

  # GET /domains/<id>
  def show
    id = params[:id]
    Rails.logger.debug "Getting domain #{id}"
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: id)
      @domain_name = domain.namespace
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "SHOW_DOMAIN", true, "Found domain #{id}")
      return render_success(:ok, "domain", get_rest_domain(domain), "SHOW_DOMAIN", "Found domain #{id}")
    rescue Mongoid::Errors::DocumentNotFound
      render_error(:not_found, "Domain #{id} not found.", 127, "SHOW_DOMAIN")
    end
  end

  # POST /domains
  def create
    namespace = params[:id]
    Rails.logger.debug "Creating domain with namespace #{namespace}"

    if Domain.where(namespace: namespace).count > 0
      return render_error(:unprocessable_entity, "Namespace '#{namespace}' is already in use. Please choose another.", 103, "ADD_DOMAIN", "id")
    end

    if Domain.where(owner: @cloud_user).count > 0
      return render_error(:conflict, "There is already a namespace associated with this user", 103, "ADD_DOMAIN", "id")
    end

    domain = Domain.new(namespace: namespace, owner: @cloud_user, users: [@cloud_user._id])
    if not domain.valid?
      Rails.logger.error "Domain is not valid"
      messages = get_error_messages(domain, {"namespace" => "id"})
      return render_error(:unprocessable_entity, nil, nil, "ADD_DOMAIN", nil, nil, messages)
    end

    @domain_name = domain.namespace
    begin
      domain.save
    rescue Exception => e
      return render_exception(e, "ADD_DOMAIN") 
    end

    render_success(:created, "domain", get_rest_domain(domain), "ADD_DOMAIN", "Created domain with namespace #{namespace}")
  end

  # PUT /domains/<existing_id>
  def update
    id = params[:existing_id]
    new_namespace = params[:id]
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: id)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain '#{id}' not found", 127, "UPDATE_DOMAIN")
    end
    
    if Domain.where(namespace: new_namespace).count > 0
      return render_error(:unprocessable_entity, "Namespace '#{new_namespace}' is already in use. Please choose another.", 106, "UPDATE_DOMAIN", "id")
    end

    domain.namespace = new_namespace
    if not domain.valid?
      messages = get_error_messages(domain, {"namespace" => "id"})
      return render_error(:unprocessable_entity, nil, nil, "UPDATE_DOMAIN", nil, nil, messages)
    end
    
    @domain_name = domain.namespace
    Rails.logger.debug "Updating domain #{domain.namespace} to #{new_namespace}"

    begin
      domain.update_namespace(new_namespace)
      domain.save
    rescue Exception => e
      return render_exception(e, "UPDATE_DOMAIN") 
    end
    
    render_success(:ok, "domain", get_rest_domain(domain), "UPDATE_DOMAIN", "Updated domain #{id} to #{new_namespace}")
  end

  # DELETE /domains/<id>
  def destroy
    id = params[:id]
    force = get_bool(params[:force])

    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: id)
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{id} not found", 127,"DELETE_DOMAIN")
    end

    if force
      domain.applications.each do |app|
        app.destroy_app
      end
    elsif not domain.applications.empty?
      return render_error(:bad_request, "Domain contains applications. Delete applications first or set force to true.", 128, "DELETE_DOMAIN")
    end

    @domain_name = domain.namespace
    begin
      domain.delete
      render_success(:no_content, nil, nil, "DELETE_DOMAIN", "Domain #{id} deleted.", true)
    rescue Exception => e
      return render_exception(e, "DELETE_DOMAIN") 
    end
  end
  
  private
  
  def get_rest_domain(domain)
    if $requested_api_version == 1.0
      domain = RestDomain10.new(domain, get_url, nolinks)
    else
      domain = RestDomain.new(domain, get_url, nolinks)
    end
    domain
  end
end
