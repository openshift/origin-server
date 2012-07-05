class ApplicationsController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  include LegacyBrokerHelper
  
  # GET /domains/[domain id]/applications
  def index
    domain_id = params[:domain_id]
    domain = get_domain(domain_id)
    if not domain or not domain.hasAccess?(@cloud_user)
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "LIST_APPLICATIONS", false, "Domain '#{domain_id}' not found")
      @reply = RestReply.new(:not_found)
      @reply.messages.push(message = Message.new(:error, "Domain not found.", 127))
      respond_with @reply, :status => @reply.status
      return
    end
    
    applications = Application.find_all(@cloud_user)
    apps = Array.new
    if not applications.nil? 
      applications.each do |application|
        if application.domain.uuid = domain.uuid
          app = RestApplication.new(application, get_url)
          apps.push(app)
        end
      end
    end
    log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "LIST_APPLICATIONS", true, "Found #{apps.length} applications for domain '#{domain_id}'")
    @reply = RestReply.new(:ok, "applications", apps)
    respond_with @reply, :status => @reply.status
  end
  
  # GET /domains/[domain_id]/applications/<id>
  def show
    domain_id = params[:domain_id]
    id = params[:id]
    
    domain = get_domain(domain_id)
    if not domain or not domain.hasAccess?(@cloud_user)
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "SHOW_APPLICATION", false, "Domain '#{domain_id}' not found")
      @reply = RestReply.new(:not_found)
      @reply.messages.push(message = Message.new(:error, "Domain not found.", 127))
      respond_with @reply, :status => @reply.status
      return
    end
    
    application = Application.find(@cloud_user,id)
    
    if application.nil? or application.domain.uuid != domain.uuid
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "SHOW_APPLICATION", false, "Application '#{id}' not found")
      @reply = RestReply.new(:not_found)
      message = Message.new(:error, "Application not found.", 101)
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
    else
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "SHOW_APPLICATION", true, "Application '#{id}' found")
      app = RestApplication.new(application, get_url)
      @reply = RestReply.new(:ok, "application", app)
      respond_with @reply, :status => @reply.status
    end
  end
  
  # POST /domains/[domain_id]/applications
  def create
    domain_id = params[:domain_id]
    
    domain = get_domain(domain_id)
    if not domain or not domain.hasAccess?(@cloud_user)
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "ADD_APPLICATION", false, "Domain '#{domain_id}' not found")
      @reply = RestReply.new(:not_found)
      @reply.messages.push(message = Message.new(:error, "Domain not found.", 127))
      respond_with @reply, :status => @reply.status
      return
    end
    
    app_name = params[:name]
    cartridge = params[:cartridge]
    scale = get_bool(params[:scale])
    
    template_id = params[:template]
    node_profile = params[:gear_profile]
    if not node_profile 
      node_profile = "small"
    else
      node_profile.downcase!
    end

    if app_name.nil? or app_name.empty?
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "ADD_APPLICATION", false, "Application name is required and cannot be blank")
      @reply = RestReply.new(:unprocessable_entity)
      message = Message.new(:error, "Application name is required and cannot be blank", 105, "name") 
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
      return
    end

    application = Application.find(@cloud_user,app_name)
    if not application.nil?
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "ADD_APPLICATION", false, "An application with name '#{app_name}' already exists")
      @reply = RestReply.new(:unprocessable_entity)
      message = Message.new(:error, "The supplied application name '#{app_name}' already exists", 100, "name") 
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
      return
    end
    Rails.logger.debug "Checking to see if user limit for number of apps has been reached"
    if (@cloud_user.consumed_gears >= @cloud_user.max_gears)
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "ADD_APPLICATION", false, "Reached gear limit of #{@cloud_user.max_gears}")
      @reply = RestReply.new(:unprocessable_entity)
      message = Message.new(:error, "#{@login} has already reached the gear limit of #{@cloud_user.max_gears}", 104)
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
      return
    end
    application = nil
    
    if not template_id.nil?
      template = ApplicationTemplate.find(params[:template])
      if template.nil?
        log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "ADD_APPLICATION", false, "Invalid template #{template_id}")
        @reply = RestReply.new(:unprocessable_entity)
        message = Message.new(:error, "Invalid template.", 125, "template") 
        @reply.messages.push(message)
        respond_with @reply, :status => @reply.status
        return
      end
      application = Application.new(@cloud_user, app_name, nil, node_profile, nil, template, scale, domain)
    else
      if cartridge.nil? or not CartridgeCache.cartridge_names('standalone').include?(cartridge)
        log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "ADD_APPLICATION", false, "Invalid cartridge #{cartridge}")
        @reply = RestReply.new(:unprocessable_entity)
        carts = get_cached("cart_list_standalone", :expires_in => 21600.seconds) {Application.get_available_cartridges("standalone")}
        message = Message.new(:error, "Invalid cartridge.  Valid values are (#{carts.join(', ')})", 109, "cartridge") 
        @reply.messages.push(message)
        respond_with @reply, :status => @reply.status
        return
      end
      application = Application.new(@cloud_user, app_name, nil, node_profile, cartridge, nil, scale, domain)
    end

    app_configure_reply = nil

    Rails.logger.debug "Validating application"  
    if application.valid?
      begin
        Rails.logger.debug "Creating application #{application.name}"
        application.create
        Rails.logger.debug "Configuring dependencies #{application.name}"
        app_configure_reply = application.configure_dependencies
        Rails.logger.debug "Executing connections for #{application.name}"
        application.execute_connections
        begin
          Rails.logger.debug "Creating dns"
          application.create_dns
        rescue Exception => e
          log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "ADD_APPLICATION", false, "Failed to create dns for application #{application.name}: #{e.message}")
          application.destroy_dns
          raise
        end
      rescue Exception => e
        log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "ADD_APPLICATION", false, "Failed to create application #{application.name}: #{e.message}")
        Rails.logger.debug e.backtrace.inspect
        application.deconfigure_dependencies
        application.destroy
        if application.persisted?
          application.delete
        end
    
        if e.kind_of? StickShift::UserException
          @reply = RestReply.new(:unprocessable_entity)
        elsif e.kind_of? StickShift::DNSException
          @reply = RestReply.new(:service_unavailable)
        else
          @reply = RestReply.new(:internal_server_error)
        end
        
        error_code = e.respond_to?("code") ? e.code : 1
        message = Message.new(:error, "Failed to create application #{application.name} due to: #{e.message}", error_code) 
        @reply.messages.push(message)
        respond_with @reply, :status => @reply.status
        return
      end
      # application.stop
      # application.start

      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "ADD_APPLICATION", true, "Created application #{application.name}")

      app = RestApplication.new(application, get_url)
      @reply = RestReply.new( :created, "application", app)
      message = Message.new(:info, "Application #{application.name} was created.")
      @reply.messages.push(message)
      
      current_ip = application.get_public_ip_address
      unless current_ip.nil? or current_ip.empty?
        message = Message.new(:info, "#{current_ip}", 0, "current_ip")
        @reply.messages.push(message)
      end

      if app_configure_reply
        message = Message.new(:info, app_configure_reply.resultIO.string, 0, :result)
        @reply.messages.push(message)
      end
      respond_with @reply, :status => @reply.status
    else
      validation_errors = []
      @reply = RestReply.new(:unprocessable_entity)
      application.errors.keys.each do |key|
        error_messages = application.errors.get(key)
        error_messages.each do |error_message|
          @reply.messages.push(Message.new(:error, error_message[:message], error_message[:exit_code], key))
          validation_errors.push(error_message[:message])
        end
      end
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "ADD_APPLICATION", false, "#{validation_errors.join('. ')}")
      respond_with @reply, :status => @reply.status
    end
  end
  
  # DELELTE domains/[domain_id]/applications/[id]
  def destroy
    domain_id = params[:domain_id]
    
    domain = get_domain(domain_id)
    if not domain or not domain.hasAccess?(@cloud_user)
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "DELETE_APPLICATION", false, "Domain #{domain_id} not found")
      Rails.logger.debug "Domain #{domain_id}"
      @reply = RestReply.new(:not_found)
      @reply.messages.push(message = Message.new(:error, "Domain not found.", 127))
      respond_with(@reply) do |format|
        format.xml { render :xml => @reply, :status => @reply.status }
        format.json { render :json => @reply, :status => @reply.status }
      end
      return
    end
    
    id = params[:id]
    
    application = Application.find(@cloud_user,id)
    if application.nil? or application.domain.uuid != domain.uuid
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "DELETE_APPLICATION", false, "Application #{id} not found")
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
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "DELETE_APPLICATION", false, "Failed to delete application #{id}: #{e.message}")
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
 
    log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "DELETE_APPLICATION", true, "Deleted application #{id}")
    @reply = RestReply.new(:no_content)
    message = Message.new(:info, "Application #{id} is deleted.")
    @reply.messages.push(message)
    respond_with(@reply) do |format|
      format.xml { render :xml => @reply, :status => @reply.status }
      format.json { render :json => @reply, :status => @reply.status }
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
