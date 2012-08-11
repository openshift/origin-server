class ApplicationsController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  include LegacyBrokerHelper
  
  # GET /domains/[domain id]/applications
  def index
    domain_id = params[:domain_id]
    
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: domain_id)
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "LIST_APPLICATIONS", true, "Found domain #{domain_id}")
    rescue Mongoid::Errors::DocumentNotFound
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "LIST_APPLICATIONS", false, "Domain #{domain_id} not found")
      @reply = RestReply.new(:not_found)
      @reply.messages.push(message = Message.new(:error, "Domain not found.", 127))
      respond_with @reply, :status => @reply.status
    end

    apps = domain.applications.map! { |applications| RestApplication.new(application, get_url, nolinks) }
    log_action(@request_id, @cloud_user._id, @cloud_user.login, "LIST_APPLICATIONS", true, "Found #{apps.length} applications for domain '#{domain_id}'")
    @reply = RestReply.new(:ok, "applications", apps)
    respond_with @reply, :status => @reply.status
  end
  
  # GET /domains/[domain_id]/applications/<id>
  def show
    domain_id = params[:domain_id]
    id = params[:id]
    
    domain = get_domain(domain_id)
    if not domain or not domain.hasAccess?(@cloud_user)
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "SHOW_APPLICATION", false, "Domain '#{domain_id}' not found")
      @reply = RestReply.new(:not_found)
      @reply.messages.push(message = Message.new(:error, "Domain not found.", 127))
      respond_with @reply, :status => @reply.status
      return
    end
    
    application = Application.find(@cloud_user,id)
    
    if application.nil? or application.domain.uuid != domain.uuid
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "SHOW_APPLICATION", false, "Application '#{id}' not found")
      @reply = RestReply.new(:not_found)
      message = Message.new(:error, "Application not found.", 101)
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
    else
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "SHOW_APPLICATION", true, "Application '#{id}' found")
      app = RestApplication.new(application, get_url, nolinks)
      @reply = RestReply.new(:ok, "application", app)
      respond_with @reply, :status => @reply.status
    end
  end
  
  # POST /domains/[domain_id]/applications
  def create
    domain_id = params[:domain_id]
    
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: domain_id)
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "LIST_APPLICATIONS", true, "Found domain #{domain_id}")
    rescue Mongoid::Errors::DocumentNotFound
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "LIST_APPLICATIONS", false, "Domain #{domain_id} not found")
      @reply = RestReply.new(:not_found)
      @reply.messages.push(message = Message.new(:error, "Domain not found.", 127))
      respond_with @reply, :status => @reply.status
      return
    end
    
    app_name = params[:name]
    cartridge = params[:cartridge]
    template_id = params[:template]

    application = Application.new(name: app_name, cartridges: [cartridge], domain: domain)

    if application.invalid?
      app_validation_errors = []
      @reply = RestReply.new(:unprocessable_entity)
      application.errors.keys.each do |field|
        error_messages = application.errors.get(field)
        error_messages.each do |error_message|
          app_validation_errors.push(error_message)
          @reply.messages.push(Message.new(:error, error_message, Application.validation_map[field], field))
        end
      end
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "ADD_APPLICATION", false, "#{app_validation_errors.join('. ')}")
      respond_with @reply, :status => @reply.status
      return
    end

    if Application.where(domain: domain, name: app_name).count > 0
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "ADD_APPLICATION", false, "An application with name '#{app_name}' already exists")
      @reply = RestReply.new(:unprocessable_entity)
      message = Message.new(:error, "The supplied application name '#{app_name}' already exists", 100, "name") 
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
      return
    end

    ##elaborate
    ##make sure enough gears are available and add to todo
    ##application.execute_connections
    ##application.create_dns
    ##current_ip = application.get_public_ip_address
    
    app = RestApplication.new(application, get_url, nolinks)
    reply = RestReply.new( :created, "application", app)
    message = Message.new(:info, "Application #{application.name} was created.")    
    respond_with reply, :status => @reply.status
  end
  
  # DELELTE domains/[domain_id]/applications/[id]
  def destroy
    domain_id = params[:domain_id]
    id = params[:id]    
    
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: domain_id)
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "LIST_APPLICATIONS", true, "Found domain #{domain_id}")
    rescue Mongoid::Errors::DocumentNotFound
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "LIST_APPLICATIONS", false, "Domain #{domain_id} not found")
      @reply = RestReply.new(:not_found)
      @reply.messages.push(message = Message.new(:error, "Domain not found.", 127))
      respond_with @reply, :status => @reply.status
      return
    end
    
    application = Application.find(@cloud_user,id)
    if application.nil? or application.domain.uuid != domain.uuid
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "DELETE_APPLICATION", false, "Application #{id} not found")
      @reply = RestReply.new(:not_found)
      message = Message.new(:error, "Application not found.", 101)
      @reply.messages.push(message)
      respond_with(@reply) do |format|
         format.xml { render :xml => @reply, :status => @reply.status }
         format.json { render :json => @reply, :status => @reply.status }
      end
      return
    end
    
    begin
      Rails.logger.debug "Deleting application #{id}"
      application.cleanup_and_delete()
    rescue Exception => e
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "DELETE_APPLICATION", false, "Failed to delete application #{id}: #{e.message}")
      @reply = e.kind_of?(StickShift::DNSException) ? RestReply.new(:service_unavailable) : RestReply.new(:internal_server_error)
      error_code = e.respond_to?('code') ? e.code : 1
      message = Message.new(:error, "Failed to delete application #{id} due to:#{e.message}", error_code) 
      @reply.messages.push(message)
      respond_with(@reply) do |format|
         format.xml { render :xml => @reply, :status => @reply.status }
         format.json { render :json => @reply, :status => @reply.status }
      end
      return
    end
 
    log_action(@request_id, @cloud_user._id, @cloud_user.login, "DELETE_APPLICATION", true, "Deleted application #{id}")
    @reply = RestReply.new(:no_content)
    message = Message.new(:info, "Application #{id} is deleted.")
    @reply.messages.push(message)
    respond_with(@reply) do |format|
      format.xml { render :xml => @reply, :status => @reply.status }
      format.json { render :json => @reply, :status => @reply.status }
    end
  end
end
