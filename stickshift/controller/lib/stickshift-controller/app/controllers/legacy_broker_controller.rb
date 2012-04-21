class LegacyBrokerController < ApplicationController
  layout nil
  before_filter :validate_request, :process_notification
  before_filter :authenticate, :except => :cart_list_post
  rescue_from Exception, :with => :exception_handler
  include LegacyBrokerHelper
  
  def user_info_post
    user = CloudUser.find(@login)
    if user
      user.auth_method = @auth_method
      user_info = user.as_json
      #FIXME: This is redundant, for now keeping it for backward compatibility
      key_info = user.get_ssh_key
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
      if user.domains and user.domains.length > 0
        user_info["namespace"] = user.domains.first.namespace
      end
      user_info[:rhc_domain] = Rails.configuration.ss[:domain_suffix]
      app_info = {}
      user.applications.each do |app|
        app_info[app.name] = {
          "framework" => app.framework,
          "creation_time" => app.creation_time,
          "uuid" => app.uuid,
          "aliases" => app.aliases,
          "embedded" => app.embedded
        }
      end
      
      @reply.data = {:user_info => user_info, :app_info => app_info}.to_json
      render :json => @reply
    else
      # Return a 404 to denote the user doesn't exist
      @reply.resultIO << "User does not exist"
      @reply.exitcode = 99
      
      render :json => @reply, :status => :not_found
    end
  end
  
  def ssh_keys_post
    user = CloudUser.find(@login)
    if user
      user.auth_method = @auth_method    
      case @req.action
      when "add-key"
        raise StickShift::UserKeyException.new("Missing SSH key or key name", 119) if @req.ssh.nil? or @req.key_name.nil?
        if user.ssh_keys
          raise StickShift::UserKeyException.new("Key with name #{@req.key_name} already exists.  Please choose a different name", 120) if user.ssh_keys.has_key?(@req.key_name)
        end
        user.add_ssh_key(@req.key_name, @req.ssh, @req.key_type)
        user.save
      when "remove-key"
        raise StickShift::UserKeyException.new("Missing key name", 119) if @req.key_name.nil?
        user.remove_ssh_key(@req.key_name)
        user.save
      when "update-key"
        raise StickShift::UserKeyException.new("Missing SSH key or key name", 119) if @req.ssh.nil? or @req.key_name.nil?
        user.update_ssh_key(@req.ssh, @req.key_type, @req.key_name)
        user.save
      when "list-keys"
        #FIXME: when client tools are updated
        if user.ssh_keys.nil? || user.ssh_keys.empty?
          @reply.data = {:keys => {}, :ssh_key => "", :ssh_type => ""}.to_json
        else
          other_keys = user.ssh_keys.reject {|k, v| k == CloudUser::DEFAULT_SSH_KEY_NAME }
          if user.ssh_keys.has_key?(CloudUser::DEFAULT_SSH_KEY_NAME)
            default_key = user.ssh_keys[CloudUser::DEFAULT_SSH_KEY_NAME]['key'] 
            default_key_type = user.ssh_keys[CloudUser::DEFAULT_SSH_KEY_NAME]['type']
          else
            default_key = default_key_type = ""            
          end
          
          @reply.data = { :keys => other_keys, 
                        :ssh_key => default_key,
                        :ssh_type => default_key_type,
                      }.to_json
        end
      else
        raise StickShift::UserKeyException.new("Invalid action #{@req.action}", 111)
      end
      render :json => @reply
    else
      raise StickShift::UserException.new("Invalid user", 99)
    end
  end
  
  def domain_post
    cloud_user = CloudUser.find(@login)
    cloud_user.auth_method = @auth_method unless cloud_user.nil?
    domain = get_domain(cloud_user, @req.namespace)
    domain = cloud_user.domains.first if !domain && @req.alter
    
    if (!domain or not domain.hasFullAccess?(cloud_user)) && (@req.alter || @req.delete)
      Rails.logger.debug "Cannot alter or remove namespace #{@req.namespace}. Namespace does not exist.\n"
      @reply.resultIO << "Cannot alter or remove namespace #{@req.namespace}. Namespace does not exist.\n"
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
        end
      rescue Exception => e
       Rails.logger.error "Failed to update domain #{domain.uuid} from #{domain.namespace} to #{@req.namespace} #{e.message}"
       Rails.logger.error e.backtrace
       raise
      end

      if @req.ssh
        cloud_user.update_ssh_key(@req.ssh, @req.key_type, @req.key_name)
        cloud_user.save
      end
    elsif @req.delete
       if not domain.hasFullAccess?(cloud_user)
         @reply.resultIO << "Cannot remove namespace #{@req.namespace}. This namespace is not associated with login: #{cloud_user.login}\n"
         @reply.exitcode = 106
         render :json => @reply, :status => :bad_request
         return
       end
       if not cloud_user.applications.empty?
         cloud_user.applications.each do |app|
           if app.domain.uuid == domain.uuid
             @reply.resultIO << "Cannot remove namespace #{@namespace}. Remove existing app(s) first: "
             @reply.resultIO << cloud_user.applications.map{|a| a.name}.join("\n")
             @reply.exitcode = 106 
             render :json => @reply, :status => :bad_request
         return
           end
         end
       end
       @reply.append domain.delete
       #@reply.append cloud_user.delete
       render :json => @reply
       return
    else
      raise StickShift::UserException.new("The supplied namespace '#{@req.namespace}' is not allowed", 106) if StickShift::ApplicationContainerProxy.blacklisted? @req.namespace
      raise StickShift::UserException.new("User already has a domain associated. Update the domain to modify.", 102) if !cloud_user.domains.empty?

      #cloud_user = CloudUser.new(@login, @req.ssh, @req.namespace, @req.key_type)
      key = Key.new(CloudUser::DEFAULT_SSH_KEY_NAME, @req.key_type, @req.ssh)
      if key.invalid?
         @reply.resultIO << key.errors.first[1][:message]
         @reply.exitcode = key.errors.first[1][:exit_code]
         render :json => @reply, :status => :bad_request 
         return
      end
      cloud_user.add_ssh_key(CloudUser::DEFAULT_SSH_KEY_NAME, @req.ssh, @req.key_type)
      domain = Domain.new(@req.namespace, cloud_user)
      @reply.append domain.save
    end

    @reply.append cloud_user.save
    @reply.data = {
      :rhlogin    => cloud_user.login,
      :uuid       => cloud_user.uuid,
      :rhc_domain => Rails.configuration.ss[:domain_suffix]
    }.to_json
      
    render :json => @reply
  end
  
  def cart_list_post
    cart_type = @req.cart_type                                                                                                                                                                                                                                    
    unless cart_type
      @reply.resultIO << "Invalid cartridge types: #{cart_type} specified"
      @reply.exitcode = 109
      render :json => @reply, :status => :bad_request
      return
    end
  
    cache_key = "cart_list_#{cart_type}"                                                                                                                                                                                                 
    carts = get_cached(cache_key, :expires_in => 21600.seconds) {
      Application.get_available_cartridges(cart_type)
    }
    @reply.data = { :carts => carts }.to_json
    render :json => @reply
  end
  
  def cartridge_post
    @req.node_profile ||= "small"
    user = CloudUser.find(@login)
    raise StickShift::UserException.new("Invalid user", 99) if user.nil?
    user.auth_method = @auth_method
    
    case @req.action
    when 'configure'    #create app and configure framework
      apps = user.applications
      domain = user.domains.first
      app = Application.new(user, @req.app_name, nil, @req.node_profile, @req.cartridge, nil, false, domain)
      check_cartridge_type(@req.cartridge, "standalone")
      if (user.consumed_gears >= user.max_gears)
        raise StickShift::UserException.new("#{@login} has already reached the application limit of #{user.max_gears}", 104)
      end
      raise StickShift::UserException.new("The supplied application name '#{app.name}' is not allowed", 105) if StickShift::ApplicationContainerProxy.blacklisted? app.name
      if app.valid?
        begin
          Rails.logger.debug "Creating application #{app.name}"
          @reply.append app.create
          Rails.logger.debug "Configuring dependencies #{app.name}"
          @reply.append app.configure_dependencies
          #@reply.append app.add_node_settings

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
            Rails.logger.error "failed to create application #{app.name} #{e.message}"
            Rails.logger.debug e.backtrace
            @reply.append app.destroy_dns
            raise
          end
        rescue Exception => e
          Rails.logger.error "failed to create application #{app.name} #{e.message}"
          Rails.logger.debug e.backtrace
          @reply.append app.deconfigure_dependencies
          @reply.append app.destroy
          if app.persisted?
            app.delete
          end
          raise
        end
        @reply.resultIO << "Successfully created application: #{app.name}" if @reply.resultIO.length == 0
      else
        @reply.result = app.errors.first[1][:message]
        render :json => @reply, :status => :bad_request 
        return
      end
    when 'deconfigure'
      app = get_app_from_request(user)      
      @reply.append app.cleanup_and_delete
      @reply.resultIO << "Successfully destroyed application: #{app.name}" if @reply.resultIO.length == 0
    when 'start'
      app = get_app_from_request(user)
      @reply.append app.start(app.framework)
    when 'stop'
      app = get_app_from_request(user)
      @reply.append app.stop(app.framework)
    when 'restart'
      app = get_app_from_request(user)
      @reply.append app.restart(app.framework)
    when 'force-stop'
      app = get_app_from_request(user)
      @reply.append app.force_stop(app.framework)
    when 'reload'
      app = get_app_from_request(user)
      @reply.append app.reload(app.framework)
    when 'status'
      app = get_app_from_request(user)
      @reply.append app.status(app.framework)
    when 'tidy'
      app = get_app_from_request(user)
      @reply.append app.tidy(app.framework)
    when 'add-alias'
      app = get_app_from_request(user)
      @reply.append app.add_alias @req.server_alias
    when 'remove-alias'
      app = get_app_from_request(user)
      @reply.append app.remove_alias @req.server_alias
    when 'threaddump'
      app = get_app_from_request(user)
      @reply.append app.threaddump(app.framework)
    when 'expose-port'
      app = get_app_from_request(user)
      @reply.append app.expose_port(app.framework)
    when 'conceal-port'
      app = get_app_from_request(user)
      @reply.append app.conceal_port(app.framework)
    when 'show-port'
      app = get_app_from_request(user)
      @reply.append app.show_port(app.framework)
    when 'system-messages'
      app = get_app_from_request(user)
      @reply.append app.system_messages
    else
      raise StickShift::UserException.new("Invalid action #{@req.action}", 111)
    end
    @reply.resultIO << 'Success' if @reply.resultIO.length == 0
    
    render :json => @reply
  end
  
  def embed_cartridge_post
    user = CloudUser.find(@login)
    raise StickShift::UserException.new("Invalid user", 99) if user.nil?
    user.auth_method = @auth_method
    
    app = get_app_from_request(user)    
    check_cartridge_type(@req.cartridge, "embedded")

    Rails.logger.debug "DEBUG: Performing action '#{@req.action}'"    
    case @req.action
    when 'configure'
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
        raise StickShift::UserException.new(110), "Invalid application type (-t|--type) specified: '#{framework}'.  Valid application types are (#{carts.join(', ')})."
      else
        raise StickShift::UserException.new(110), "Invalid type (-e|--embed) specified: '#{framework}'.  Valid embedded types are (#{carts.join(', ')})."
      end
    end
  end
  
  def get_app_from_request(user)
    app = Application.find(user, @req.app_name)
    raise StickShift::UserException.new("An application named '#{@req.app_name}' does not exist", 101) if app.nil?
    return app
  end
  
  def validate_request
    @reply = ResultIO.new
    begin
      @req = LegacyRequest.new.from_json(params['json_data'])
      if @req.invalid?
        @reply.resultIO << @req.errors.first[1][:message]
        @reply.exitcode = @req.errors.first[1][:exit_code]
        render :json => @reply, :status => :bad_request 
      end
    end
  end
  
  def authenticate
    begin
      auth = StickShift::AuthService.instance.login(request, params, cookies)
  
      if auth  
        @login = auth[:username]
        @auth_method = auth[:auth_method]
        
        Rails.logger.debug "Adding user #{@login}...inside legacy_controller"
        @cloud_user = CloudUser.find @login
        if @cloud_user.nil?
          @cloud_user = CloudUser.new(@login)
          @cloud_user.save
        end
      end
      unless @login
        @reply.resultIO << "Invalid user credentials"
        @reply.exitcode = 97
        render :json => @reply, :status => :unauthorized
      end
    rescue StickShift::AccessDeniedException
      @reply.resultIO << "Invalid user credentials"
      @reply.exitcode = 97
      render :json => @reply, :status => :unauthorized
    end
  end
  
  def exception_handler(e)
    status = :internal_server_error
    
    case e
    when StickShift::AuthServiceException
      logger.error "AuthenticationException rescued in #{request.path}"
      logger.error e.message
      logger.error e.backtrace[0..5].join("\n")
      @reply.append e.resultIO if e.resultIO
      @reply.resultIO << "An error occurred while contacting the authentication service. If the problem persists please contact Red Hat support." if @reply.resultIO.length == 0
    when StickShift::UserException
      @reply.resultIO << e.message
      status = :bad_request
    when StickShift::SSException
      logger.error "Exception rescued in #{request.path}:"
      logger.error e.message
      logger.error e.backtrace[0..5].join("\n")
      logger.error e.resultIO
      @reply.resultIO << e.message if @reply.resultIO.length == 0
      @reply.append e.resultIO if e.resultIO
    else
      logger.error "Exception rescued in #{request.path}:"
      logger.error e.message
      logger.error e.backtrace
      @reply.debugIO << e.message
      @reply.debugIO << e.backtrace[0..5].join("\n")
      @reply.resultIO << e.message if @reply.resultIO.length == 0
    end
    
    @reply.exitcode = e.respond_to?('exit_code') ? e.exit_code : 1
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
end
