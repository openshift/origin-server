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
    log_action(@request_id, @cloud_user._id, @cloud_user.login, "LIST_DOMAINS")
    @reply = RestReply.new(:ok, "domains", rest_domains)
    respond_with @reply, :status => @reply.status
  end

  # GET /domains/<id>
  def show
    id = params[:id]
    Rails.logger.debug "Getting domain #{id}"
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: id)
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "SHOW_DOMAIN", true, "Found domain #{id}")
      domain = RestDomain.new(domain, get_url, nolinks)
      @reply = RestReply.new(:ok, "domain", domain)
      respond_with @reply, :status => @reply.status
    rescue Mongoid::Errors::DocumentNotFound
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "SHOW_DOMAIN", false, "Domain #{id} not found")
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

    domain = Domain.new(namespace: namespace, owner: @cloud_user, users: [@cloud_user])
    if not domain.valid?
      Rails.logger.error "Domain is not valid"
      @reply = RestReply.new(:unprocessable_entity)
      domain.errors.keys.each do |key|
        field = key.to_s == "namespace" ? "id": key.to_s 
        error_messages = domain.errors.get(key)
        error_messages.each do |error_message|
          @reply.messages.push(Message.new(:error, error_message, Domain.validation_map[field], field))
          log_messages.push(error_message)
        end
      end
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "ADD_DOMAIN", false, log_messages.join(', '))
      respond_with @reply, :status => @reply.status
      return
    end

    if Domain.where(namespace: namespace).count > 0
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "ADD_DOMAIN", false, "Namespace '#{namespace}' is already in use")
      @reply = RestReply.new(:unprocessable_entity)
      @reply.messages.push(Message.new(:error, "Namespace '#{namespace}' is already in use. Please choose another.", 103, "id"))
      respond_with @reply, :status => @reply.status
      return
    end

    begin
      domain.save
    rescue Exception => e
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "ADD_DOMAIN", false, "Failed to create domain '#{namespace}': #{e.message}")
      Rails.logger.error e.backtrace
      @reply = e.kind_of?(StickShift::DNSException) ? RestReply.new(:service_unavailable) : RestReply.new(:internal_server_error)
      error_code = e.respond_to?('code') ? e.code : 1
      @reply.messages.push(Message.new(:error, e.message, error_code))
      respond_with @reply, :status => @reply.status
      return
    end

    log_action(@request_id, @cloud_user._id, @cloud_user.login, "ADD_DOMAIN", true, "Created domain with namespace #{namespace}")
    domain = RestDomain.new(domain, get_url, nolinks)
    @reply = RestReply.new(:created, "domain", domain)
    respond_with @reply, :status => @reply.status
  end

  # PUT /domains/<existing_id>
  def update
    id = params[:existing_id]
    new_namespace = params[:id]
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: id)
    rescue Mongoid::Errors::DocumentNotFound
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "UPDATE_DOMAIN", false, "Domain '#{id}' not found")
      @reply = RestReply.new(:not_found)
      @reply.messages.push(message = Message.new(:error, "Domain not found.", 127))
      respond_with @reply, :status => @reply.status
      return
    end

    domain.namespace = new_namespace
    if not domain.valid?
      log_messages = []
      @reply = RestReply.new(:unprocessable_entity)
      new_domain.errors.keys.each do |key|
        field = key.to_s == "namespace" ? "id": key.to_s 
        error_messages = new_domain.errors.get(key)
        error_messages.each do |error_message|
          @reply.messages.push(Message.new(:error, error_message, Domain.validation_map[field], field))
          log_messages.push(error_message)
        end
      end
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "UPDATE_DOMAIN", false, log_messages.join(', '))
      respond_with @reply, :status => @reply.status
      return
    end

    Rails.logger.debug "Updating domain #{domain.namespace} to #{new_namespace}"

    if Domain.where(namespace: new_namespace).count > 0
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "ADD_DOMAIN", false, "Namespace '#{namespace}' is already in use")
      @reply = RestReply.new(:unprocessable_entity)
      @reply.messages.push(Message.new(:error, "Namespace '#{namespace}' is already in use. Please choose another.", 103, "id"))
      respond_with @reply, :status => @reply.status
      return
    end

    begin
      domain.save
    rescue Exception => e
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "UPDATE_DOMAIN", false, e.message)
      Rails.logger.error "Failed to update domain #{e.message} #{e.backtrace}"
      @reply = e.kind_of?(StickShift::DNSException) ? RestReply.new(:service_unavailable) : RestReply.new(:internal_server_error)
      error_code = e.respond_to?('code') ? e.code : 1
      @reply.messages.push(Message.new(:error, e.message, error_code))
      respond_with @reply, :status => @reply.status
      return
    end
    
    @reply = RestReply.new(:ok, "domain", RestDomain.new(domain, get_url, nolinks))
    log_action(@request_id, @cloud_user._id, @cloud_user.login, "UPDATE_DOMAIN", true, "Updated domain #{id} to #{new_namespace}")
    respond_with @reply, :status => @reply.status
  end

  # DELETE /domains/<id>
  def destroy
    id = params[:id]
    force = get_bool(params[:force])

    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: id)
    rescue Mongoid::Errors::DocumentNotFound
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "UPDATE_DOMAIN", false, "Domain '#{id}' not found")
      @reply = RestReply.new(:not_found)
      @reply.messages.push(message = Message.new(:error, "Domain not found.", 127))
      respond_with @reply, :status => @reply.status
      return
    end

    if force
      Rails.logger.debug "Force deleting domain #{id}"
      domain.applications.each do |app|
        app.cleanup_and_delete()
      end
    elsif not domain.applications.empty?
      app = @cloud_user.applications.first
      @reply = RestReply.new(:bad_request)
      @reply.messages.push(Message.new(:error, "Domain contains applications. Delete applications first or set force to true.", 128))
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "DELETE_DOMAIN", false, "Domain '#{id}' contains applications")
      respond_with @reply, :status => @reply.status
      return
    end

    begin
      domain.delete
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "DELETE_DOMAIN", true, "Domain '#{id}' deleted")
      @reply = RestReply.new(:no_content)
      @reply.messages.push(Message.new(:info, "Domain deleted."))
      respond_with @reply, :status => @reply.status
    rescue Exception => e
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "DELETE_DOMAIN", false, "Failed to delete domain '#{id}': #{e.message}")
      @reply = e.kind_of?(StickShift::DNSException) ? RestReply.new(:service_unavailable) : RestReply.new(:internal_server_error)
      error_code = e.respond_to?('code') ? e.code : 1
      @reply.messages.push(Message.new(:error, e.message, error_code))
      respond_with @reply, :status => @reply.status
    end
  end
end
