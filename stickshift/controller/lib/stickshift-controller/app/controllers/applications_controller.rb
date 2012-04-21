class ApplicationsController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  include LegacyBrokerHelper
  
  # GET /domains/[domain id]/applications
  def index
    domain_id = params[:domain_id]
    domain = get_domain(domain_id)
     if not domain or not domain.hasAccess?(@cloud_user)
       Rails.logger.debug "Domain #{domain_id}"
      @reply = RestReply.new(:not_found)
      @reply.messages.push(message = Message.new(:error, "Domain #{domain_id} not found.", 127))
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
    @reply = RestReply.new(:ok, "applications", apps)
    respond_with @reply, :status => @reply.status
  end
  
  # GET /domains/[domain_id]/applications/<id>
  def show
    domain_id = params[:domain_id]
    id = params[:id]
    
    domain = get_domain(domain_id)
     if not domain or not domain.hasAccess?(@cloud_user)
      Rails.logger.debug "Domain #{domain_id}"
      @reply = RestReply.new(:not_found)
      @reply.messages.push(message = Message.new(:error, "Domain #{domain_id} not found.", 127))
      respond_with @reply, :status => @reply.status
      return
    end
    
    application = Application.find(@cloud_user,id)
    
    if application.nil? or application.domain.uuid != domain.uuid
      @reply = RestReply.new(:not_found)
      message = Message.new(:error, "Application #{id} not found.", 101)
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
    else
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
       Rails.logger.debug "Domain #{domain_id}"
      @reply = RestReply.new(:not_found)
      @reply.messages.push(message = Message.new(:error, "Domain #{domain_id} not found.", 127))
      respond_with @reply, :status => @reply.status
      return
    end
    
    app_name = params[:name]
    cartridge = params[:cartridge]
    scale_str = params[:scale]
    
    if not scale_str.nil? and scale_str.upcase == "TRUE"
      scale = true
    else
      scale = false
    end

    template_id = params[:template]
    node_profile = params[:gear_profile]
    if not node_profile 
      node_profile = "small"
    else
      node_profile.downcase!
    end

    if app_name.nil? or app_name.empty?
      @reply = RestReply.new(:unprocessable_entity)
      message = Message.new(:error, "Application name is required and cannot be blank", 105, "name") 
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
      return
    end

    application = Application.find(@cloud_user,app_name)
    if not application.nil?
      @reply = RestReply.new(:unprocessable_entity)
      message = Message.new(:error, "The supplied application name '#{app_name}' already exists", 100, "name") 
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
      return
    end
    Rails.logger.debug "Checking to see if user limit for number of apps has been reached"
    if (@cloud_user.consumed_gears >= @cloud_user.max_gears)
      @reply = RestReply.new(:forbidden)
      message = Message.new(:error, "#{@login} has already reached the application limit of #{@cloud_user.max_gears}", 104)
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
      return
    end
    application = nil
    
    if not template_id.nil?
      template = ApplicationTemplate.find(params[:template])
      if template.nil?
        @reply = RestReply.new(:unprocessable_entity)
        message = Message.new(:error, "Invalid template #{params[:template]}.", 125, "template") 
        @reply.messages.push(message)
        respond_with @reply, :status => @reply.status
      end
      application = Application.new(@cloud_user, app_name, nil, node_profile, nil, template, scale, domain)
    else
      if cartridge.nil? or not CartridgeCache.cartridge_names('standalone').include?(cartridge)
        @reply = RestReply.new(:unprocessable_entity)
        carts = get_cached("cart_list_standalone", :expires_in => 21600.seconds) {Application.get_available_cartridges("standalone")}
        message = Message.new(:error, "Invalid cartridge #{cartridge}.  Valid values are (#{carts.join(', ')})", 109, "cartridge") 
        @reply.messages.push(message)
        respond_with @reply, :status => @reply.status
        return
      end
      application = Application.new(@cloud_user, app_name, nil, node_profile, cartridge, nil, scale, domain)
    end

    Rails.logger.debug "Validating application"  
    if application.valid?
      begin
        Rails.logger.debug "Creating application #{application.name}"
        application.create
        Rails.logger.debug "Configuring dependencies #{application.name}"
        application.configure_dependencies
        #Rails.logger.debug "Adding node settings #{application.name}"
        #application.add_node_settings
        Rails.logger.debug "Executing connections for #{application.name}"
        application.execute_connections
        begin
          Rails.logger.debug "Creating dns"
          application.create_dns
        rescue Exception => e
            Rails.logger.error e
            application.destroy_dns
            @reply = RestReply.new(:internal_server_error)
            message = Message.new(:error, "Failed to create dns for application #{application.name} due to:#{e.message}") 
            @reply.messages.push(message)
            message = Message.new(:error, "Failed to create application #{application.name} due to DNS failure.") 
            @reply.messages.push(message)
            application.deconfigure_dependencies
            application.destroy
            application.delete
            respond_with @reply, :status => @reply.status
            return
        end
      rescue Exception => e
        Rails.logger.debug e.message
        Rails.logger.debug e.backtrace.inspect
        application.deconfigure_dependencies
        application.destroy
        if application.persisted?
          application.delete
        end
    
        @reply = RestReply.new(:internal_server_error)
        message = Message.new(:error, "Failed to create application #{application.name} due to:#{e.message}") 
        @reply.messages.push(message)
        respond_with @reply, :status => @reply.status
        return
      end
      # application.stop
      # application.start
      
      app = RestApplication.new(application, get_url)
      @reply = RestReply.new( :created, "application", app)
      message = Message.new(:info, "Application #{application.name} was created.")
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
    else
      @reply = RestReply.new(:unprocessable_entity)
      application.errors.keys.each do |key|
        error_messages = application.errors.get(key)
        error_messages.each do |error_message|
          @reply.messages.push(Message.new(:error, error_message[:message], error_message[:exit_code], key))
        end
      end
      respond_with @reply, :status => @reply.status
    end
  end
  
  # DELELTE domains/[domain_id]/applications/[id]
  def destroy
    domain_id = params[:domain_id]
    
    domain = get_domain(domain_id)
     if not domain or not domain.hasAccess?(@cloud_user)
      Rails.logger.debug "Domain #{domain_id}"
      @reply = RestReply.new(:not_found)
      @reply.messages.push(message = Message.new(:error, "Domain #{domain_id} not found.", 127))
      respond_with(@reply) do |format|
        format.xml { render :xml => @reply, :status => @reply.status }
        format.json { render :json => @reply, :status => @reply.status }
      end
      return
    end
    
    id = params[:id]
    
    application = Application.find(@cloud_user,id)
    if application.nil? or application.domain.uuid != domain.uuid
      @reply = RestReply.new(:not_found)
      message = Message.new(:error, "Application #{id} not found.", 101)
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
      Rails.logger.error "Failed to Delete application #{id}: #{e.message}"
      @reply = RestReply.new(:internal_server_error)
      message = Message.new(:error, "Failed to delete application #{id} due to:#{e.message}", e.code) 
      @reply.messages.push(message)
      respond_with(@reply) do |format|
         format.xml { render :xml => @reply, :status => @reply.status }
         format.json { render :json => @reply, :status => @reply.status }
      end
      return
    end
 
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
