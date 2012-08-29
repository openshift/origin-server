class LegacyBrokerController < BaseController
  layout nil
  before_filter :validate_request, :process_notification
  before_filter :authenticate, :except => :cart_list_post
  rescue_from Exception, :with => :exception_handler
  include UserActionLogger
  
  # Get User login, domains and application for display using the Legacy Non-REST APIs
  #
  # == Returns:
  # Hash of user info:
  #   rhlogin [String]    The user login
  #   ssh_key [String]    The user's default ssh key
  #   ssh_type [String]   The user's default ssh key type
  #   namespace [String]  The user's first namespace
  #   app_info [Array]    List of user applications in the first namespace
  #   app_info[framework]     [String]  Name of the web_framework cartridge
  #   app_info[creation_time] [String]  When the application was created
  #   app_info[uuid]          [String]  UUID of the application
  #   app_info[aliases]       [Array]   List of aliases associated with the application
  #   app_info[embedded]      [String]  List of embedded cartridges
  def user_info_post
    unless @cloud_user.nil?
      user_info = {}
      user_info[:rhc_domain] = Rails.configuration.ss[:domain_suffix]
      user_info["rhlogin"] = @cloud_user.login
      user_info["uuid"] = @cloud_user._id.to_s      
      user_info["namespace"] = @cloud_user.domains.first.namespace

      #FIXME: This is redundant, for now keeping it for backward compatibility
      if @cloud_user.ssh_keys.length > 0
        key_info = @cloud_user.ssh_keys[0]
        user_info["ssh_key"] = key_info['key']
        user_info["ssh_type"] = key_info['type']
      else
        user_info["ssh_key"] = ""
        user_info["ssh_type"] = ""
      end
      
      user_info["ssh_keys"] = {}
      @cloud_user.ssh_keys.each do |key|
        user_info["ssh_keys"][key.name] = {type: key.type, key: key.content}
      end
      
      user_info["max_gears"] = @cloud_user.max_gears
      user_info["consumed_gears"] = @cloud_user.consumed_gears
      user_info["capabilities"] = @cloud_user.capabilities
      
      # this is to support old version of client tools
      app_info = {}
      user_info["domains"] = @cloud_user.domains.map do |domain|
        d_hash = {}
        d_hash["namespace"] = domain.namespace

        domain.applications.each do |app|
          app_info[app.name] = {
            "framework" => "",
            "creation_time" => app.created_at,
            "uuid" => app._id.to_s,
            "aliases" => app.aliases,
            "embedded" => {}
          }

          app.requires(true).each do |feature|
            cart = CartridgeCache.find_cartridge(feature)
            if cart.categories.include? "web_framework"
              app_info[app.name]["framework"] = cart.name
            else
              app_info[app.name]["embedded"][cart.name] = {}
            end
          end
        end
        d_hash
      end
      
      log_action(@request_id, @cloud_user._id.to_s, @login, "LEGACY_USER_INFO")
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
  
  # Update a users ssh keys
  def ssh_keys_post
    unless @cloud_user.nil?
      case @req.action
      when "add-key"
        raise StickShift::UserKeyException.new("Missing SSH key or key name", 119) if @req.ssh.nil? or @req.key_name.nil?
        raise StickShift::UserKeyException.new("Key with name #{@req.key_name} already exists.  Please choose a different name", 120) if @cloud_user.ssh_keys.where(name: @req.key_name).count > 0
        @cloud_user.add_ssh_key(SshKey.new(name: @req.key_name, content: @req.ssh, type: @req.key_type))
      when "remove-key"
        raise StickShift::UserKeyException.new("Missing key name", 119) if @req.key_name.nil?
        @cloud_user.remove_ssh_key(@req.key_name)
      when "update-key"
        raise StickShift::UserKeyException.new("Missing SSH key or key name", 119) if @req.ssh.nil? or @req.key_name.nil?
        @cloud_user.update_ssh_key(SshKey.new(name: @req.key_name, content: @req.ssh, type: @req.key_type))
      when "list-keys"
        if @cloud_user.ssh_keys.nil? || @cloud_user.ssh_keys.empty?
          @reply.data = {:keys => {}, :ssh_key => "", :ssh_type => ""}.to_json
        else
          default_key = nil
          other_keys  = {}
          @cloud_user.ssh_keys.each do |key|
            if key.name == CloudUser::DEFAULT_SSH_KEY_NAME
              default_key = key 
            else
              other_keys[key.name] = {"type" => key.type, "key" => key.content}
            end
          end
          
          default_key = default_key_type = "" if default_key.nil?
          @reply.data = { :keys => other_keys, 
                        :ssh_key => default_key.content,
                        :ssh_type => default_key.type
                      }.to_json
        end
      else
        raise StickShift::UserKeyException.new("Invalid action #{@req.action}", 111)
      end
      log_action(@request_id, @cloud_user._id.to_s, @login, "LEGACY_SSH_KEY", true, "Successfully completed action: #{@req.action}")
      render :json => @reply
    else
      raise StickShift::UserException.new("Invalid user", 99)
    end
  end
  
  def domain_post
    domain = get_domain(@cloud_user, @req.namespace)
    domain = @cloud_user.domains.first if !domain && @req.alter
    
    if (!domain or not domain.hasFullAccess?(@cloud_user)) && (@req.alter || @req.delete)
      log_action(@request_id, @cloud_user._id.to_s, @login, "LEGACY_ALTER_DOMAIN", false, "Cannot alter or remove namespace #{@req.namespace}. Namespace does not exist.")
      @reply.resultIO << "Cannot alter or remove namespace #{@req.namespace}. Namespace does not exist.\n"
      @reply.exitcode = 106
      render :json => @reply, :status => :bad_request
      return
    end

    if @req.alter
      Rails.logger.debug "Updating namespace for domain #{domain.uuid} from #{domain.namespace} to #{@req.namespace}"
      raise StickShift::UserException.new("The supplied namespace '#{@req.namespace}' is not allowed", 106) if StickShift::ApplicationContainerProxy.blacklisted? @req.namespace   
      begin
        if domain.namespace != @req.namespace
          domain.namespace = @req.namespace     
          @reply.append domain.save
          log_action(@request_id, @cloud_user._id.to_s, @login, "LEGACY_ALTER_DOMAIN", true, "Updated namespace for domain #{domain.uuid} to #{@req.namespace}")
        end
      rescue Exception => e
       log_action(@request_id, @cloud_user._id.to_s, @login, "LEGACY_ALTER_DOMAIN", false, "Failed to updated namespace for domain #{domain.uuid} to #{@req.namespace}")
       Rails.logger.error "Failed to update domain #{domain.uuid} from #{domain.namespace} to #{@req.namespace} #{e.message}"
       Rails.logger.error e.backtrace
       raise
      end

      if @req.ssh
        @cloud_user.update_ssh_key(@req.ssh, @req.key_type, @req.key_name)
        @cloud_user.save
        log_action(@request_id, @cloud_user._id.to_s, @login, "LEGACY_ALTER_DOMAIN", true, "Updated SSH key '#{@req.key_name}' for domain #{domain.namespace}")
      end
    elsif @req.delete
       if not domain.hasFullAccess?(@cloud_user)
         log_action(@request_id, @cloud_user._id.to_s, @login, "LEGACY_DELETE_DOMAIN", false, "Domain #{domain.namespace} is not associated with user")
         @reply.resultIO << "Cannot remove namespace #{@req.namespace}. This namespace is not associated with login: #{@cloud_user.login}\n"
         @reply.exitcode = 106
         render :json => @reply, :status => :bad_request
         return
       end
       if not @cloud_user.applications.empty?
         @cloud_user.applications.each do |app|
           if app.domain.uuid == domain.uuid
             log_action(@request_id, @cloud_user._id.to_s, @login, "LEGACY_DELETE_DOMAIN", false, "Domain #{domain.namespace} contains applications")
             @reply.resultIO << "Cannot remove namespace #{@req.namespace}. Remove existing app(s) first: "
             @reply.resultIO << @cloud_user.applications.map{|a| a.name}.join("\n")
             @reply.exitcode = 106 
             render :json => @reply, :status => :bad_request
         return
           end
         end
       end
       @reply.append domain.delete
       log_action(@request_id, @cloud_user._id.to_s, @login, "LEGACY_DELETE_DOMAIN", true, "Deleted domain #{@req.namespace}")
       render :json => @reply
       return
    else
      raise StickShift::UserException.new("The supplied namespace '#{@req.namespace}' is not allowed", 106) if StickShift::ApplicationContainerProxy.blacklisted? @req.namespace
      raise StickShift::UserException.new("Domain already exists for user. Update the domain to modify.", 158) if !@cloud_user.domains.empty?

      key = Key.new(CloudUser::DEFAULT_SSH_KEY_NAME, @req.key_type, @req.ssh)
      if key.invalid?
         log_action(@request_id, @cloud_user._id.to_s, @login, "LEGACY_CREATE_DOMAIN", false, "Failed to create domain #{@req.namespace}: #{key.errors.first[1][:message]}")
         @reply.resultIO << key.errors.first[1][:message]
         @reply.exitcode = key.errors.first[1][:exit_code]
         render :json => @reply, :status => :bad_request 
         return
      end
      @cloud_user.add_ssh_key(CloudUser::DEFAULT_SSH_KEY_NAME, @req.ssh, @req.key_type)
      domain = Domain.new(@req.namespace, @cloud_user)
      @reply.append domain.save
      log_action(@request_id, @cloud_user._id.to_s, @login, "LEGACY_CREATE_DOMAIN", true, "Created domain #{@req.namespace}")
    end

    @reply.append @cloud_user.save
    @reply.data = {
      :rhlogin    => @cloud_user.login,
      :uuid       => @cloud_user._id.to_s,
      :rhc_domain => Rails.configuration.ss[:domain_suffix]
    }.to_json
      
    render :json => @reply
  end
  
  # returns a list of cartridges
  def cart_list_post
    cart_type = @req.cart_type                                                                                                                                                                                                                                    
    unless cart_type
      log_action('nil', 'nil', 'nil', "LEGACY_CART_LIST", false, "Cartridge type not specified")
      @reply.resultIO << "Invalid cartridge types: #{cart_type} specified"
      @reply.exitcode = 109
      render :json => @reply, :status => :bad_request
      return
    end
    
    cart_type = "web_framework" if cart_type == "standalone"
    cache_key = "cart_list_#{cart_type}"                                                                                                                                         
    carts = CartridgeCache.cartridge_names(cart_type)
    log_action('nil', 'nil', 'nil', "LEGACY_CART_LIST")
    @reply.data = { :carts => carts }.to_json
    render :json => @reply
  end
  
  def cartridge_post
    raise StickShift::UserException.new("Invalid user", 99) if @cloud_user.nil?
    
    case @req.action
    when 'configure'    #create app and configure framework
      domain = @cloud_user.domains.first
      check_cartridge_type(@req.cartridge, "standalone")
      raise StickShift::UserException.new("The supplied application name '#{app.name}' is not allowed", 105) if StickShift::ApplicationContainerProxy.blacklisted? @req.app_name
      
      #@req.node_profile
      begin
        app = Application.new(domain: domain, features: [@req.cartridge], name: @req.app_name)
      rescue StickShift::GearLimitReachedException => e
        raise StickShift::UserException.new("#{@login} has already reached the gear limit of #{@cloud_user.max_gears}", 104)
      end

      if app.valid?
        @reply.append app.run_jobs
        case @req.cartridge
        when 'php'
          page = 'health_check.php'
        when 'perl'
          page = 'health_check.pl'
        else
          page = 'health'
        end
        @reply.data = {:health_check_path => page, :uuid => app.uuid}.to_json
        log_action(@request_id, @cloud_user._id.to_s, @login, "LEGACY_CREATE_APP", true, "Created application #{app.name}")
        @reply.resultIO << "Successfully created application: #{app.name}" if @reply.resultIO.length == 0
      else
        log_action(@request_id, @cloud_user._id.to_s, @login, "LEGACY_CREATE_APP", false, "Invalid application: #{app.errors.first[1][:message]}")
        @reply.resultIO << app.errors.first[1][:message]
        @reply.exitcode = app.errors.first[1][:exit_code]
        render :json => @reply, :status => :bad_request 
        return
      end
    when 'deconfigure'
      app = get_app_from_request(@cloud_user)
      app.destroy_app
      @reply.append app.run_jobs
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
      raise StickShift::UserException.new("Invalid action #{@req.action}", 111)
    end
    @reply.resultIO << 'Success' if @reply.resultIO.length == 0
    log_action(@request_id, @cloud_user._id.to_s, @login, "LEGACY_CARTRIDGE_POST", true, "Processed event #{@req.action} for application #{app.name}")
    
    render :json => @reply
  end
  
  def embed_cartridge_post
    raise StickShift::UserException.new("Invalid user", 99) if @cloud_user.nil?
    
    app = get_app_from_request(@cloud_user)    
    check_cartridge_type(@req.cartridge, "embedded")
    
    # making this check here for the specific actions, so that the error codes for other conditions are not affected
    if ['deconfigure', 'start', 'stop', 'restart', 'status', 'reload'].include?(@req.action) and ( app.embedded.nil? or not app.embedded.has_key?(@req.cartridge) )
      raise StickShift::UserException.new("The application #{app.name} is not configured with the embedded cartridge #{@req.cartridge}.", 129) 
    end

    Rails.logger.debug "DEBUG: Performing action '#{@req.action}'"    
    case @req.action
    when 'configure'
      if app.scalable && (@cloud_user.consumed_gears >= @cloud_user.max_gears) && @req.cartridge != 'jenkins-client-1.4'  #TODO Need a proper method to let us know if cart will get its own gear
        raise StickShift::UserException.new("#{@login} has already reached the gear limit of #{@cloud_user.max_gears}", 104)
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
      raise StickShift::UserException.new("Invalid action #{@req.action}", 111)           
    end
    
    log_action(@request_id, @cloud_user._id.to_s, @login, "LEGACY_EMBED_CARTRIDGE_POST", true, "Processed event #{@req.action} for cartridge #{@req.cartridge} of application #{app.name}")
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
    cart_type = "web_framework" if cart_type == "standalone"
    carts = CartridgeCache.cartridge_names(cart_type)
    unless carts.include?(framework)
      if cart_type == 'web_framework'
        raise StickShift::UserException.new(110), "Invalid application type (-t|--type) specified: '#{framework}'.  Valid application types are (#{carts.join(', ')})."
      else
        raise StickShift::UserException.new(110), "Invalid type (-c|--cartridge) specified: '#{framework}'.  Valid cartridge types are (#{carts.join(', ')})."
      end
    end
  end
  
  def get_app_from_request(user)
    begin
      domains = user.domains
      app = Application.find_by(:domain.in => domains, name: @req.app_name)
    rescue Mongoid::Errors::DocumentNotFound
      raise StickShift::UserException.new("An application named '#{@req.app_name}' does not exist", 101) if app.nil?    
    end

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
      auth = StickShift::AuthService.instance.login(request, params, cookies)

      if auth  
        @login = auth[:username]
        @auth_method = auth[:auth_method]

        @cloud_user = CloudUser.find_by(login: @login)
        if @cloud_user.nil?
          Rails.logger.debug "Adding user #{@login}...inside legacy_controller"
          @cloud_user = CloudUser.new(login: @login)
          begin
            @cloud_user.save
          rescue Exception => e
            cu = CloudUser.find_by(login: @login)
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
    rescue StickShift::AccessDeniedException
      log_action('nil','nil', 'nil', "LEGACY_BROKER", false, "Authentication failed: Invalid user credentials")
      @reply.resultIO << "Invalid user credentials"
      @reply.exitcode = 97
      render :json => @reply, :status => :unauthorized
    end
  end

  def exception_handler(e)
    status = :internal_server_error
    
    case e
    when StickShift::AuthServiceException
      log_action(@request_id, 'nil', 'nil', "LEGACY_BROKER", false, "#{e.class.name} for #{request.path}: #{e.message}")
      Rails.logger.error e.backtrace[0..5].join("\n")
      @reply.append e.resultIO if e.resultIO
      @reply.resultIO << "An error occurred while contacting the authentication service. If the problem persists please contact Red Hat support." if @reply.resultIO.length == 0
    when StickShift::UserException
      log_action(@request_id.nil? ? 'nil' : @request_id, @cloud_user.nil? ? 'nil' : @cloud_user._id.to_s, @login.nil? ? 'nil' : @login, "LEGACY_BROKER", false, "#{e.class.name} for #{request.path}: #{e.message}")
      @reply.resultIO << e.message
      status = :bad_request
    when StickShift::DNSException
      log_action(@request_id.nil? ? 'nil' : @request_id, @cloud_user.nil? ? 'nil' : @cloud_user._id.to_s, @login.nil? ? 'nil' : @login, "LEGACY_BROKER", false, "#{e.class.name} for #{request.path}: #{e.message}")
      @reply.resultIO << e.message
      status = :service_unavailable
    when StickShift::SSException
      log_action(@request_id.nil? ? 'nil' : @request_id, @cloud_user.nil? ? 'nil' : @cloud_user._id.to_s, @login.nil? ? 'nil' : @login, "LEGACY_BROKER", false, "#{e.class.name} for #{request.path}: #{e.message}")
      Rails.logger.error e.backtrace[0..5].join("\n")
      Rails.logger.error e.resultIO
      @reply.resultIO << e.message if @reply.resultIO.length == 0
      @reply.append e.resultIO if e.resultIO
    else
      log_action(@request_id.nil? ? 'nil' : @request_id, @cloud_user.nil? ? 'nil' : @cloud_user._id.to_s, @login.nil? ? 'nil' : @login, "LEGACY_BROKER", false, "#{e.class.name} for #{request.path}: #{e.message}")
      Rails.logger.error e.backtrace
      @reply.debugIO << e.message
      @reply.debugIO << e.backtrace[0..5].join("\n")
      @reply.resultIO << e.message if @reply.resultIO.length == 0
    end
    
    @reply.exitcode = e.respond_to?('code') ? e.code : 1
    render :json => @reply, :status => status
  end
  
  def get_domain(cloud_user, id)
    domains = Domain.where(owner: cloud_user, namespace: id)
    if domain.count > 1
      return domains.first
    end
    domains = Domain.where(user_ids: cloud_user._id, namespace: id)
    if domain.count > 1
      return domains.first
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
