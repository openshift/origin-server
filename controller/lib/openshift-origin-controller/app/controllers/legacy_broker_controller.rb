class LegacyBrokerController < ApplicationController
  layout nil
  before_filter :validate_request, :process_notification
  before_filter :authenticate, :except => :cart_list_post
  rescue_from Exception, :with => :exception_handler
  include LegacyBrokerHelper
  include UserActionLogger
  
  def user_info_post
    if @cloud_user
      user_info = @cloud_user.as_json
      #FIXME: This is redundant, for now keeping it for backward compatibility
      key_info = @cloud_user.get_ssh_key
      if key_info
        user_info["ssh_key"] = key_info['key']
        user_info["ssh_type"] = key_info['type']
      else
        user_info["ssh_key"] = ""
        user_info["ssh_type"] = ""
      end
        
      user_info["rhlogin"] = user_info["login"]
      user_info.delete("login") 
      # this is to support old version of client tools
      if @cloud_user.domains and @cloud_user.domains.length > 0
        user_info["namespace"] = @cloud_user.domains.first.namespace
      end
      user_info[:rhc_domain] = Rails.configuration.ss[:domain_suffix]
      app_info = {}
      unless @cloud_user.applications.nil?
        @cloud_user.applications.each do |app|
          app_info[app.name] = {
            "framework" => app.framework,
            "creation_time" => app.creation_time,
            "uuid" => app.uuid,
            "aliases" => app.aliases,
            "embedded" => app.embedded
          }
        end
      end
      
      log_action(@request_id, @cloud_user.uuid, @login, "LEGACY_USER_INFO")
      @reply.data = {:user_info => user_info, :app_info => app_info}.to_json
      render :json => @reply
    else
      log_action(@request_id, "nil", @login, "LEGACY_USER_INFO", false, "User not found")
      # Return a 404 to denote the user doesn't exist
      @reply.resultIO << "User does not exist"
      @reply.exitcode = 99
      
      render :json => @reply, :status => :not_found
    end
  end
  
  def ssh_keys_post
    if @cloud_user    
      case @req.action
      when "add-key"
        raise OpenShift::UserKeyException.new("Missing SSH key or key name", 119) if @req.ssh.nil? or @req.key_name.nil?
        if @cloud_user.ssh_keys
          raise OpenShift::UserKeyException.new("Key with name #{@req.key_name} already exists.  Please choose a different name", 120) if @cloud_user.ssh_keys.has_key?(@req.key_name)
        end
        @cloud_user.add_ssh_key(@req.key_name, @req.ssh, @req.key_type)
        @cloud_user.save
      when "remove-key"
        raise OpenShift::UserKeyException.new("Missing key name", 119) if @req.key_name.nil?
        @cloud_user.remove_ssh_key(@req.key_name)
        @cloud_user.save
      when "update-key"
        raise OpenShift::UserKeyException.new("Missing SSH key or key name", 119) if @req.ssh.nil? or @req.key_name.nil?
        @cloud_user.update_ssh_key(@req.ssh, @req.key_type, @req.key_name)
        @cloud_user.save
      when "list-keys"
        #FIXME: when client tools are updated
        if @cloud_user.ssh_keys.nil? || @cloud_user.ssh_keys.empty?
          @reply.data = {:keys => {}, :ssh_key => "", :ssh_type => ""}.to_json
        else
          other_keys = @cloud_user.ssh_keys.reject {|k, v| k == CloudUser::DEFAULT_SSH_KEY_NAME }
          if @cloud_user.ssh_keys.has_key?(CloudUser::DEFAULT_SSH_KEY_NAME)
            default_key = @cloud_user.ssh_keys[CloudUser::DEFAULT_SSH_KEY_NAME]['key'] 
            default_key_type = @cloud_user.ssh_keys[CloudUser::DEFAULT_SSH_KEY_NAME]['type']
          else
            default_key = default_key_type = ""            
          end
          
          @reply.data = { :keys => other_keys, 
                        :ssh_key => default_key,
                        :ssh_type => default_key_type,
                      }.to_json
        end
      else
        raise OpenShift::UserKeyException.new("Invalid action #{@req.action}", 111)
      end
      log_action(@request_id, @cloud_user.uuid, @login, "LEGACY_SSH_KEY", true, "Successfully completed action: #{@req.action}")
      render :json => @reply
    else
      raise OpenShift::UserException.new("Invalid user", 99)
    end
  end
  
  def domain_post
    domain = get_domain(@cloud_user, @req.namespace)
    domain = @cloud_user.domains.first if !domain && @req.alter
    
    if (!domain or not domain.hasFullAccess?(@cloud_user)) && (@req.alter || @req.delete)
      log_action(@request_id, @cloud_user.uuid, @login, "LEGACY_ALTER_DOMAIN", false, "Cannot alter or remove namespace #{@req.namespace}. Namespace does not exist.")
      @reply.resultIO << "Cannot alter or remove namespace #{@req.namespace}. Namespace does not exist.\n"
      @reply.exitcode = 106
      render :json => @reply, :status => :bad_request
      return
    end

    if @req.alter
      
      Rails.logger.debug "Updating namespace for domain #{domain.uuid} from #{domain.namespace} to #{@req.namespace}"

      raise OpenShift::UserException.new("The supplied namespace '#{@req.namespace}' is not allowed", 106) if OpenShift::ApplicationContainerProxy.blacklisted? @req.namespace   
      begin
        if domain.namespace != @req.namespace
          domain.namespace = @req.namespace     
          @reply.append domain.save
          log_action(@request_id, @cloud_user.uuid, @login, "LEGACY_ALTER_DOMAIN", true, "Updated namespace for domain #{domain.uuid} to #{@req.namespace}")
        end
      rescue Exception => e
       log_action(@request_id, @cloud_user.uuid, @login, "LEGACY_ALTER_DOMAIN", false, "Failed to updated namespace for domain #{domain.uuid} to #{@req.namespace}")
       Rails.logger.error "Failed to update domain #{domain.uuid} from #{domain.namespace} to #{@req.namespace} #{e.message}"
       Rails.logger.error e.backtrace
       raise
      end

      if @req.ssh
        @cloud_user.update_ssh_key(@req.ssh, @req.key_type, @req.key_name)
        @cloud_user.save
        log_action(@request_id, @cloud_user.uuid, @login, "LEGACY_ALTER_DOMAIN", true, "Updated SSH key '#{@req.key_name}' for domain #{domain.namespace}")
      end
    elsif @req.delete
       if not domain.hasFullAccess?(@cloud_user)
         log_action(@request_id, @cloud_user.uuid, @login, "LEGACY_DELETE_DOMAIN", false, "Domain #{domain.namespace} is not associated with user")
         @reply.resultIO << "Cannot remove namespace #{@req.namespace}. This namespace is not associated with login: #{@cloud_user.login}\n"
         @reply.exitcode = 106
         render :json => @reply, :status => :bad_request
         return
       end
       if not @cloud_user.applications.empty?
         @cloud_user.applications.each do |app|
           if app.domain.uuid == domain.uuid
             log_action(@request_id, @cloud_user.uuid, @login, "LEGACY_DELETE_DOMAIN", false, "Domain #{domain.namespace} contains applications")
             @reply.resultIO << "Cannot remove namespace #{@req.namespace}. Remove existing app(s) first: "
             @reply.resultIO << @cloud_user.applications.map{|a| a.name}.join("\n")
             @reply.exitcode = 106 
             render :json => @reply, :status => :bad_request
         return
           end
         end
       end
       @reply.append domain.delete
       log_action(@request_id, @cloud_user.uuid, @login, "LEGACY_DELETE_DOMAIN", true, "Deleted domain #{@req.namespace}")
       render :json => @reply
       return
    else
      raise OpenShift::UserException.new("The supplied namespace '#{@req.namespace}' is not allowed", 106) if OpenShift::ApplicationContainerProxy.blacklisted? @req.namespace
      raise OpenShift::UserException.new("Domain already exists for user. Update the domain to modify.", 158) if !@cloud_user.domains.empty?

      key = Key.new(CloudUser::DEFAULT_SSH_KEY_NAME, @req.key_type, @req.ssh)
      if key.invalid?
         log_action(@request_id, @cloud_user.uuid, @login, "LEGACY_CREATE_DOMAIN", false, "Failed to create domain #{@req.namespace}: #{key.errors.first[1][:message]}")
         @reply.resultIO << key.errors.first[1][:message]
         @reply.exitcode = key.errors.first[1][:exit_code]
         render :json => @reply, :status => :bad_request 
         return
      end
      @cloud_user.add_ssh_key(CloudUser::DEFAULT_SSH_KEY_NAME, @req.ssh, @req.key_type)
      domain = Domain.new(@req.namespace, @cloud_user)
      @reply.append domain.save
      log_action(@request_id, @cloud_user.uuid, @login, "LEGACY_CREATE_DOMAIN", true, "Created domain #{@req.namespace}")
    end

    @reply.append @cloud_user.save
    @reply.data = {
      :rhlogin    => @cloud_user.login,
      :uuid       => @cloud_user.uuid,
      :rhc_domain => Rails.configuration.ss[:domain_suffix]
    }.to_json
      
    render :json => @reply
  end
  
  def cart_list_post
    cart_type = @req.cart_type                                                                                                                                                                                                                                    
    unless cart_type
      log_action('nil', 'nil', 'nil', "LEGACY_CART_LIST", false, "Cartridge type not specified")
      @reply.resultIO << "Invalid cartridge types: #{cart_type} specified"
      @reply.exitcode = 109
      render :json => @reply, :status => :bad_request
      return
    end
  
    cache_key = "cart_list_#{cart_type}"                                                                                                                                         
    carts = get_cached(cache_key, :expires_in => 21600.seconds) {
      Application.get_available_cartridges(cart_type)
    }
    log_action('nil', 'nil', 'nil', "LEGACY_CART_LIST")
    @reply.data = { :carts => carts }.to_json
    render :json => @reply
  end
  
  def cartridge_post
    raise OpenShift::UserException.new("Invalid user", 99) if @cloud_user.nil?
    
    case @req.action
    when 'configure'    #create app and configure framework
      apps = @cloud_user.applications
      domain = @cloud_user.domains.first
      app = Application.new(@cloud_user, @req.app_name, nil, @req.node_profile, @req.cartridge, nil, false, domain)
      check_cartridge_type(@req.cartridge, "standalone")
      if (@cloud_user.consumed_gears >= @cloud_user.max_gears)
        raise OpenShift::UserException.new("#{@login} has already reached the gear limit of #{@cloud_user.max_gears}", 104)
      end
      raise OpenShift::UserException.new("The supplied application name '#{app.name}' is not allowed", 105) if OpenShift::ApplicationContainerProxy.blacklisted? app.name
      if app.valid?
        begin
          Rails.logger.debug "Creating application #{app.name}"
          @reply.append app.create
          Rails.logger.debug "Configuring dependencies #{app.name}"
          @reply.append app.configure_dependencies

          app.execute_connections
          begin
            @reply.append app.create_dns
            
            case app.framework_cartridge
              when 'php'
                page = 'health_check.php'
              when 'perl'
                page = 'health_check.pl'
              else
                page = 'health'
            end
          
            @reply.data = {:health_check_path => page, :uuid => app.uuid}.to_json
          rescue Exception => e
            @reply.append app.destroy_dns
            raise
          end
        rescue Exception => e
          log_action(@request_id, @cloud_user.uuid, @login, "LEGACY_CREATE_APP", false, "Failed to create application #{app.name}: #{e.message}")
          @reply.append app.destroy
          if app.persisted?
            app.delete
          end
          @reply.resultIO = StringIO.new(e.message)
          raise
        end
        log_action(@request_id, @cloud_user.uuid, @login, "LEGACY_CREATE_APP", true, "Created application #{app.name}")
        @reply.resultIO << "Successfully created application: #{app.name}" if @reply.resultIO.length == 0
      else
        log_action(@request_id, @cloud_user.uuid, @login, "LEGACY_CREATE_APP", false, "Invalid application: #{app.errors.first[1][:message]}")
        @reply.resultIO << app.errors.first[1][:message]
        @reply.exitcode = app.errors.first[1][:exit_code]
        render :json => @reply, :status => :bad_request 
        return
      end
    when 'deconfigure'
      app = get_app_from_request(@cloud_user)
      @reply.append app.cleanup_and_delete
      @reply.resultIO << "Successfully destroyed application: #{app.name}"
    when 'start'
      app = get_app_from_request(@cloud_user)
      @reply.append app.start(app.framework)
    when 'stop'
      app = get_app_from_request(@cloud_user)
      @reply.append app.stop(app.framework)
    when 'restart'
      app = get_app_from_request(@cloud_user)
      @reply.append app.restart(app.framework)
    when 'force-stop'
      app = get_app_from_request(@cloud_user)
      @reply.append app.force_stop(app.framework)
    when 'reload'
      app = get_app_from_request(@cloud_user)
      @reply.append app.reload(app.framework)
    when 'status'
      app = get_app_from_request(@cloud_user)
      @reply.append app.status(app.framework)
    when 'tidy'
      app = get_app_from_request(@cloud_user)
      @reply.append app.tidy(app.framework)
    when 'add-alias'
      app = get_app_from_request(@cloud_user)
      @reply.append app.add_alias @req.server_alias
    when 'remove-alias'
      app = get_app_from_request(@cloud_user)
      @reply.append app.remove_alias @req.server_alias
    when 'threaddump'
      app = get_app_from_request(@cloud_user)
      @reply.append app.threaddump(app.framework)
    when 'expose-port'
      app = get_app_from_request(@cloud_user)
      @reply.append app.expose_port(app.framework)
    when 'conceal-port'
      app = get_app_from_request(@cloud_user)
      @reply.append app.conceal_port(app.framework)
    when 'show-port'
      app = get_app_from_request(@cloud_user)
      @reply.append app.show_port(app.framework)
    when 'system-messages'
      app = get_app_from_request(@cloud_user)
      @reply.append app.system_messages
    else
      raise OpenShift::UserException.new("Invalid action #{@req.action}", 111)
    end
    @reply.resultIO << 'Success' if @reply.resultIO.length == 0
    log_action(@request_id, @cloud_user.uuid, @login, "LEGACY_CARTRIDGE_POST", true, "Processed event #{@req.action} for application #{app.name}")
    
    render :json => @reply
  end
  
  def embed_cartridge_post
    raise OpenShift::UserException.new("Invalid user", 99) if @cloud_user.nil?
    
    app = get_app_from_request(@cloud_user)    
    check_cartridge_type(@req.cartridge, "embedded")
    
    # making this check here for the specific actions, so that the error codes for other conditions are not affected
    if ['deconfigure', 'start', 'stop', 'restart', 'status', 'reload'].include?(@req.action) and ( app.embedded.nil? or not app.embedded.has_key?(@req.cartridge) )
      raise OpenShift::UserException.new("The application #{app.name} is not configured with the embedded cartridge #{@req.cartridge}.", 129) 
    end

    Rails.logger.debug "DEBUG: Performing action '#{@req.action}'"    
    case @req.action
    when 'configure'
      if app.scalable && (@cloud_user.consumed_gears >= @cloud_user.max_gears) && @req.cartridge != 'jenkins-client-1.4'  #TODO Need a proper method to let us know if cart will get its own gear
        raise OpenShift::UserException.new("#{@login} has already reached the gear limit of #{@cloud_user.max_gears}", 104)
      end
      @reply.append app.add_dependency(@req.cartridge)
    when 'deconfigure'
      @reply.append app.remove_dependency(@req.cartridge)
    when 'start'
      @reply.append app.start(@req.cartridge)      
    when 'stop'
      @reply.append app.stop(@req.cartridge)      
    when 'restart'
      @reply.append app.restart(@req.cartridge)      
    when 'status'
      @reply.append app.status(@req.cartridge)      
    when 'reload'
      @reply.append app.reload(@req.cartridge)
    else
      raise OpenShift::UserException.new("Invalid action #{@req.action}", 111)           
    end
    
    log_action(@request_id, @cloud_user.uuid, @login, "LEGACY_EMBED_CARTRIDGE_POST", true, "Processed event #{@req.action} for cartridge #{@req.cartridge} of application #{app.name}")
    @reply.resultIO << 'Success' if @reply.resultIO.length == 0
    render :json => @reply
  end
  
  protected
  
  def process_notification
    message = self.notifications if self.respond_to? "notifications"
    @reply.messageIO << message unless message.nil?
  end
  
  # Raise an exception if cartridge type isn't supported
  def check_cartridge_type(framework, cart_type)
    carts = Application.get_available_cartridges(cart_type)
    unless carts.include? framework
      if cart_type == 'standalone'
        raise OpenShift::UserException.new(110), "Invalid application type (-t|--type) specified: '#{framework}'.  Valid application types are (#{carts.join(', ')})."
      else
        raise OpenShift::UserException.new(110), "Invalid type (-c|--cartridge) specified: '#{framework}'.  Valid cartridge types are (#{carts.join(', ')})."
      end
    end
  end
  
  def get_app_from_request(user)
    app = Application.find(user, @req.app_name)
    raise OpenShift::UserException.new("An application named '#{@req.app_name}' does not exist", 101) if app.nil?
    app.user_agent = request.headers["User-Agent"]
    return app
  end
  
  def validate_request
    @reply = ResultIO.new
    begin
      @req = LegacyRequest.new.from_json(params['json_data'])
      if @req.invalid?
        log_action('nil','nil', 'nil', "LEGACY_BROKER", false, "Validation error: #{@req.errors.first[1][:message]}")
        @reply.resultIO << @req.errors.first[1][:message]
        @reply.exitcode = @req.errors.first[1][:exit_code]
        render :json => @reply, :status => :bad_request 
      end
    end
  end
  
  def authenticate
    @request_id = gen_req_uuid
    begin
      auth = OpenShift::AuthService.instance.login(request, params, cookies)

      if auth  
        @login = auth[:username]
        @auth_method = auth[:auth_method]

        @cloud_user = CloudUser.find @login
        if @cloud_user.nil?
          Rails.logger.debug "Adding user #{@login}...inside legacy_controller"
          @cloud_user = CloudUser.new(@login)
          begin
            @cloud_user.save
          rescue Exception => e
            cu = CloudUser.find @login
            raise unless cu && (@cloud_user.parent_user_login == cu.parent_user_login)
            @cloud_user = cu
          end
        end
        @cloud_user.auth_method = @auth_method unless @cloud_user.nil?
      end
      unless @login
        log_action('nil','nil', 'nil', "LEGACY_BROKER", false, "Authentication failed: Invalid user credentials")
        @reply.resultIO << "Invalid user credentials"
        @reply.exitcode = 97
        render :json => @reply, :status => :unauthorized
      end
    rescue OpenShift::AccessDeniedException
      log_action('nil','nil', 'nil', "LEGACY_BROKER", false, "Authentication failed: Invalid user credentials")
      @reply.resultIO << "Invalid user credentials"
      @reply.exitcode = 97
      render :json => @reply, :status => :unauthorized
    end
  end

  def exception_handler(e)
    status = :internal_server_error
    
    case e
    when OpenShift::AuthServiceException
      log_action(@request_id, 'nil', 'nil', "LEGACY_BROKER", false, "#{e.class.name} for #{request.path}: #{e.message}")
      Rails.logger.error e.backtrace[0..5].join("\n")
      @reply.append e.resultIO if e.resultIO
      @reply.resultIO << "An error occurred while contacting the authentication service. If the problem persists please contact Red Hat support." if @reply.resultIO.length == 0
    when OpenShift::UserException
      log_action(@request_id.nil? ? 'nil' : @request_id, @cloud_user.nil? ? 'nil' : @cloud_user.uuid, @login.nil? ? 'nil' : @login, "LEGACY_BROKER", false, "#{e.class.name} for #{request.path}: #{e.message}")
      @reply.resultIO << e.message
      status = :bad_request
    when OpenShift::DNSException
      log_action(@request_id.nil? ? 'nil' : @request_id, @cloud_user.nil? ? 'nil' : @cloud_user.uuid, @login.nil? ? 'nil' : @login, "LEGACY_BROKER", false, "#{e.class.name} for #{request.path}: #{e.message}")
      @reply.resultIO << e.message
      status = :service_unavailable
    when OpenShift::OOException
      log_action(@request_id.nil? ? 'nil' : @request_id, @cloud_user.nil? ? 'nil' : @cloud_user.uuid, @login.nil? ? 'nil' : @login, "LEGACY_BROKER", false, "#{e.class.name} for #{request.path}: #{e.message}")
      Rails.logger.error e.backtrace[0..5].join("\n")
      Rails.logger.error e.resultIO
      @reply.resultIO << e.message if @reply.resultIO.length == 0
      @reply.append e.resultIO if e.resultIO
    else
      log_action(@request_id.nil? ? 'nil' : @request_id, @cloud_user.nil? ? 'nil' : @cloud_user.uuid, @login.nil? ? 'nil' : @login, "LEGACY_BROKER", false, "#{e.class.name} for #{request.path}: #{e.message}")
      Rails.logger.error e.backtrace
      @reply.debugIO << e.message
      @reply.debugIO << e.backtrace[0..5].join("\n")
      @reply.resultIO << e.message if @reply.resultIO.length == 0
    end
    
    @reply.exitcode = e.respond_to?('code') ? e.code : 1
    render :json => @reply, :status => status
  end
  
  def get_domain(cloud_user, id)
    cloud_user.domains.each do |domain|
      if domain.namespace == id
      return domain
      end
    end
    return nil
  end

  def gen_req_uuid
    # The request id can be generated differently to make it a bit more meaningful
    File.open("/proc/sys/kernel/random/uuid", "r") do |file|
      file.gets.strip.gsub("-","")
    end
  end

end
