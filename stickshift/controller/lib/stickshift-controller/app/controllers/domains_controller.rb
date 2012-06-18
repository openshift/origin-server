class DomainsController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  # GET /domains
  def index
    domains = Array.new
    Rails.logger.debug "Getting domains for user #{@cloud_user.login}"
    Rails.logger.debug @cloud_user.domains
    @cloud_user.domains.each do |domain|
      domains.push(RestDomain.new(domain, get_url))
    end
    log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "LIST_DOMAINS")
    @reply = RestReply.new(:ok, "domains", domains)
    respond_with @reply, :status => @reply.status
  end

  # GET /domains/<id>
  def show
    id = params[:id]
    Rails.logger.debug "Getting domain #{id}"
    domain = get_domain(id)
    if domain and domain.hasAccess?(@cloud_user)
      #Rails.logger.debug "Found domain #{id}"
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "SHOW_DOMAIN", true, "Found domain #{id}")
      domain = RestDomain.new(domain, get_url)
      @reply = RestReply.new(:ok, "domain", domain)
      respond_with @reply, :status => @reply.status
    else
      #Rails.logger.error "[Request ID: #{@request_id}] Domain #{id} not found"
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "SHOW_DOMAIN", false, "Domain #{id} not found")
      @reply = RestReply.new(:not_found)
      @reply.messages.push(message = Message.new(:error, "Domain not found.", 127))
      respond_with @reply, :status => @reply.status
    end
  end

  # POST /domains
  def create
    namespace = params[:id]
    Rails.logger.debug "Creating domain with namespace #{namespace}"
    log_messages = []

    domain = Domain.new(namespace, @cloud_user)
    if not domain.valid?
      Rails.logger.debug "Domain is not valid"
      Rails.logger.error "Domain is not valid"
      @reply = RestReply.new(:unprocessable_entity)
      domain.errors.keys.each do |key|
        field = key.to_s
        field = "id" if key.to_s == "namespace"
        error_messages = domain.errors.get(key)
        error_messages.each do |error_message|
          @reply.messages.push(Message.new(:error, error_message[:message], error_message[:exit_code], field))
          log_messages.push(error_message[:message])
        end
      end
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "ADD_DOMAIN", false, log_messages.join(', '))
      respond_with @reply, :status => @reply.status
    return
    end

    if not Domain.namespace_available?(namespace)
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "ADD_DOMAIN", false, "Namespace '#{namespace}' is already in use")
      @reply = RestReply.new(:unprocessable_entity)
      @reply.messages.push(Message.new(:error, "Namespace '#{namespace}' is already in use. Please choose another.", 103, "id"))
      respond_with @reply, :status => @reply.status
    return
    end

    if not @cloud_user.domains.empty?
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "ADD_DOMAIN", false, "User already has a domain associated")
      @reply = RestReply.new(:conflict)
      @reply.messages.push(Message.new(:error, "User already has a domain associated. Update the domain to modify.", 102))
      respond_with @reply, :status => @reply.status
      return
    end

    begin
      domain.save
    rescue Exception => e
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "ADD_DOMAIN", false, "Failed to create domain '#{namespace}': #{e.message}")
      Rails.logger.error e.backtrace
      @reply = e.kind_of?(StickShift::DNSException) ? RestReply.new(:service_unavailable) : RestReply.new(:internal_server_error)
      error_code = e.respond_to?('code') ? e.code : 1
      @reply.messages.push(Message.new(:error, e.message, error_code))
      respond_with @reply, :status => @reply.status
    return
    end

    log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "ADD_DOMAIN", true, "Created domain with namespace #{namespace}")
    domain = RestDomain.new(domain, get_url)
    @reply = RestReply.new(:created, "domain", domain)
    respond_with @reply, :status => @reply.status
  end

  # PUT /domains/<existing_id>
  def update
    id = params[:existing_id]
    new_namespace = params[:id]
    domain = get_domain(id)

    new_domain = Domain.new(new_namespace, @cloud_user)
    if not new_domain.valid?
      log_messages = []
      @reply = RestReply.new(:unprocessable_entity)
      new_domain.errors.keys.each do |key|
        field = key.to_s
        field = "id" if key.to_s == "namespace"
        error_messages = new_domain.errors.get(key)
        error_messages.each do |error_message|
          @reply.messages.push(Message.new(:error, error_message[:message], error_message[:exit_code], field))
          log_messages.push(error_message[:message])
        end
      end
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "UPDATE_DOMAIN", false, log_messages.join(', '))
      respond_with(@reply) do |format|
        format.xml { render :xml => @reply, :status => @reply.status }
        format.json { render :json => @reply, :status => @reply.status }
      end
    return
    end
    if not domain or not domain.hasAccess?@cloud_user
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "UPDATE_DOMAIN", false, "Domain '#{id}' not found")
      @reply = RestReply.new(:not_found)
      @reply.messages.push(message = Message.new(:error, "Domain not found.", 127))
      respond_with(@reply) do |format|
        format.xml { render :xml => @reply, :status => @reply.status }
        format.json { render :json => @reply, :status => @reply.status }
      end
    return
    end
    if domain and not domain.hasFullAccess?@cloud_user
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "UPDATE_DOMAIN", false, "User does not have permission to modify domain '#{id}'")
      @reply = RestReply.new(:forbidden)
      @reply.messages.push(message = Message.new(:error, "You do not have permission to modify this domain", 132))
      respond_with(@reply) do |format|
        format.xml { render :xml => @reply, :status => @reply.status }
        format.json { render :json => @reply, :status => @reply.status }
      end
    return
    end

    Rails.logger.debug "Updating domain #{domain.namespace} to #{new_namespace}"

    if not Domain.namespace_available?(new_namespace)
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "UPDATE_DOMAIN", false, "Namespace '#{new_namespace}' already in use")
      @reply = RestReply.new(:unprocessable_entity)
      @reply.messages.push(Message.new(:error, "Namespace '#{new_namespace}' already in use. Please choose another.", 103, "id"))
      respond_with @reply, :status => @reply.status  do |format|
        format.xml { render :xml => @reply, :status => @reply.status }
        format.json { render :json => @reply, :status => @reply.status }
      end
    return
    end

    domain.namespace = new_namespace
    if domain.invalid?
      log_messages = []
      @reply = RestReply.new(:unprocessable_entity)
      domain.errors.keys.each do |key|
        field = key
        field = "id" if key == "namespace"
        error_messages = domain.errors.get(key)
        error_messages.each do |error_message|
          @reply.messages.push(Message.new(:error, error_message[:message], error_message[:exit_code], field))
          log_messages.push(error_message[:message])
        end
      end
      
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "UPDATE_DOMAIN", false, log_messages.join(', '))
      
      respond_with(@reply) do |format|
        format.xml { render :xml => @reply, :status => @reply.status }
        format.json { render :json => @reply, :status => @reply.status }
      end
    return
    end

    begin
      domain.save
    rescue Exception => e
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "UPDATE_DOMAIN", false, e.message)
      Rails.logger.error "Failed to update domain #{e.message} #{e.backtrace}"
      @reply = e.kind_of?(StickShift::DNSException) ? RestReply.new(:service_unavailable) : RestReply.new(:internal_server_error)
      error_code = e.respond_to?('code') ? e.code : 1
      @reply.messages.push(Message.new(:error, e.message, error_code))
      respond_with(@reply) do |format|
        format.xml { render :xml => @reply, :status => @reply.status }
        format.json { render :json => @reply, :status => @reply.status }
      end
    return
    end
    @cloud_user = CloudUser.find(@login)
    domain = RestDomain.new(domain, get_url)
    @reply = RestReply.new(:ok, "domain", domain)

    log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "UPDATE_DOMAIN", true, "Updated domain #{id} to #{new_namespace}")

    respond_with(@reply) do |format|
      format.xml { render :xml => @reply, :status => @reply.status }
      format.json { render :json => @reply, :status => @reply.status }
    end
  end

  # DELETE /domains/<id>
  def destroy
    id = params[:id]
    force = get_bool(params[:force])

    domain = get_domain(id)
    if not domain or not domain.hasAccess?@cloud_user
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "DELETE_DOMAIN", false, "Domain #{id} not found")
      @reply = RestReply.new(:not_found)
      @reply.messages.push(message = Message.new(:error, "Domain not found.", 127))
      respond_with(@reply) do |format|
        format.xml { render :xml => @reply, :status => @reply.status }
        format.json { render :json => @reply, :status => @reply.status }
      end
    return
    end

    if domain and not domain.hasFullAccess?@cloud_user
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "DELETE_DOMAIN", false, "User does not have permission to delete domain '#{id}'")
      @reply = RestReply.new(:forbidden)
      @reply.messages.push(message = Message.new(:error, "You do not have permission to delete this domain", 132))
      respond_with(@reply) do |format|
        format.xml { render :xml => @reply, :status => @reply.status }
        format.json { render :json => @reply, :status => @reply.status }
      end
    return
    end

    if force
      Rails.logger.debug "Force deleting domain #{id}"
      @cloud_user.applications.each do |app|
        if app.domain.uuid == domain.uuid
        app.cleanup_and_delete()
        end
      end
    elsif not @cloud_user.applications.empty?
      @cloud_user.applications.each do |app|
        if app.domain.uuid == domain.uuid
          @reply = RestReply.new(:bad_request)
          @reply.messages.push(Message.new(:error, "Domain contains applications. Delete applications first or set force to true.", 128))

          log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "DELETE_DOMAIN", false, "Domain '#{id}' contains applications")
          
          respond_with(@reply) do |format|
            format.xml { render :xml => @reply, :status => @reply.status }
            format.json { render :json => @reply, :status => @reply.status }
          end
        return
        end
      end
    end

    begin
      domain.delete
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "DELETE_DOMAIN", true, "Domain '#{id}' deleted")
      @reply = RestReply.new(:no_content)
      @reply.messages.push(Message.new(:info, "Domain deleted."))
      respond_with(@reply) do |format|
        format.xml { render :xml => @reply, :status => @reply.status }
        format.json { render :json => @reply, :status => @reply.status }
      end
    rescue Exception => e
      #Rails.logger.error "Failed to delete domain #{e.message}"
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "DELETE_DOMAIN", false, "Failed to delete domain '#{id}': #{e.message}")
      @reply = e.kind_of?(StickShift::DNSException) ? RestReply.new(:service_unavailable) : RestReply.new(:internal_server_error)
      error_code = e.respond_to?('code') ? e.code : 1
      @reply.messages.push(Message.new(:error, e.message, error_code))
      respond_with(@reply) do |format|
        format.xml { render :xml => @reply, :status => @reply.status }
        format.json { render :json => @reply, :status => @reply.status }
      end
    return
    end
  end

  def get_domain(id)
    @cloud_user.domains.each do |domain|
      if domain.namespace == id
      return domain
      end
    end
    return nil
  end
end
