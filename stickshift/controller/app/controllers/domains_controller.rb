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
      rest_domains.push(RestDomain.new(domain, get_url, nolinks))
    end
    render_success(:ok, "domains", rest_domains, "LIST_DOMAINS")
  end

  # GET /domains/<id>
  def show
    id = params[:id]
    Rails.logger.debug "Getting domain #{id}"
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: id)
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "SHOW_DOMAIN", true, "Found domain #{id}")
      domain = RestDomain.new(domain, get_url, nolinks)
      return render_success(:ok, "domain", domain, "SHOW_DOMAIN", "Found domain #{id}")
    rescue Mongoid::Errors::DocumentNotFound
      render_error(:not_found, "Domain #{id} not found.", 127, "SHOW_DOMAIN")
    end
  end

  # POST /domains
  def create
    namespace = params[:id]
    Rails.logger.debug "Creating domain with namespace #{namespace}"

    domain = Domain.new(namespace: namespace, owner: @cloud_user, users: [@cloud_user._id])
    if not domain.valid?
      Rails.logger.error "Domain is not valid"
      messages = get_error_messages(domain, {"namespace" => "id"})
      return render_error(:unprocessable_entity, nil, nil, "ADD_DOMAIN", nil, nil, messages)
    end

    if Domain.where(namespace: namespace).count > 0
      return render_error(:unprocessable_entity, "Namespace '#{namespace}' is already in use. Please choose another.", 103, "ADD_DOMAIN", "id")
    end

    begin
      domain.save
    rescue Exception => e
      return render_exception(e, "ADD_DOMAIN") 
    end

    domain = RestDomain.new(domain, get_url, nolinks)
    render_success(:created, "domain", domain, "ADD_DOMAIN", "Created domain with namespace #{namespace}")
  end

  # PUT /domains/<existing_id>
  def update
    id = params[:existing_id]
    new_namespace = params[:id]
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: id)
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain '#{id}' not found", 127, "UPDATE_DOMAIN")
    end

    domain.namespace = new_namespace
    if not domain.valid?
      messages = get_error_messages(new_domain, "namespace", "id")
      return render_error(:unprocessable_entity, nil, nil, "UPDATE_DOMAIN", nil, nil, messages)
    end

    Rails.logger.debug "Updating domain #{domain.namespace} to #{new_namespace}"

    if Domain.where(namespace: new_namespace).count > 0
      return render_error(:unprocessable_entity, "Namespace '#{namespace}' is already in use. Please choose another.", 103, "UPDATE_DOMAIN", "id")
    end

    begin
      domain.save
    rescue Exception => e
      return render_exception(e, "UPDATE_DOMAIN") 
    end
    
    domain = RestDomain.new(domain, get_url, nolinks)
    render_success(:ok, "domain", domain, "UPDATE_DOMAIN", "Updated domain #{id} to #{new_namespace}")
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
      
    elsif not domain.applications.empty?
      app = @cloud_user.applications.first
      return render_error(:bad_request, "Domain contains applications. Delete applications first or set force to true.", 128, "DELETE_DOMAIN")
    end

    begin
      domain.delete
      render_success(:no_content, nil, nil, "DELETE_DOMAIN", "Domain #{id} deleted.", true)
    rescue Exception => e
      return render_exception(e, "DELETE_DOMAIN") 
    end
  end
end
