class BaseController < ActionController::Base
  respond_to :json, :xml
  before_filter :check_version, :only => :show
  before_filter :check_nolinks
  API_VERSION = 1.3
  SUPPORTED_API_VERSIONS = [1.0, 1.1, 1.2, 1.3]
  include OpenShift::Controller::ActionLog
  #Mongoid.logger.level = Logger::WARN
  #Moped.logger.level = Logger::WARN
  
  # Initialize domain/app variables to be used for logging in user_action.log
  # The values will be set in the controllers handling the requests
  @domain_name = nil
  @application_name = nil
  @application_uuid = nil
  
  before_filter :set_locale
  def set_locale
    # if params[:locale] is nil then I18n.default_locale will be used
    I18n.locale = nil
  end

  # Override default Rails responder to return status code and objects from PUT/POST/DELETE requests
  def respond_with(*arguments)
    super(arguments, :responder => OpenShift::Responder)
  end
  
  def show
    blacklisted_words = OpenShift::ApplicationContainerProxy.get_blacklisted
    unless nolinks
      links = {
        "API" => Link.new("API entry point", "GET", URI::join(get_url, "api")),
        "GET_ENVIRONMENT" => Link.new("Get environment information", "GET", URI::join(get_url, "environment")),
        "GET_USER" => Link.new("Get user information", "GET", URI::join(get_url, "user")),      
        "LIST_DOMAINS" => Link.new("List domains", "GET", URI::join(get_url, "domains")),
        "ADD_DOMAIN" => Link.new("Create new domain", "POST", URI::join(get_url, "domains"), [
          Param.new("id", "string", "Name of the domain",nil,blacklisted_words)
        ]),
        "LIST_CARTRIDGES" => Link.new("List cartridges", "GET", URI::join(get_url, "cartridges"))
      }
      
      base_url = Rails.application.config.openshift[:community_quickstarts_url]
      if base_url.nil?
        quickstart_links = {
          "LIST_QUICKSTARTS"   => Link.new("List quickstarts", "GET", URI::join(get_url, "quickstarts")),
          "SHOW_QUICKSTART"    => Link.new("Retrieve quickstart with :id", "GET", URI::join(get_url, "quickstarts/:id"), [
            Param.new(":id", "string", "Unique identifier of the quickstart", nil, [])
          ]),
        }
        links.merge! quickstart_links
      else
        base_url = URI.join(get_url, base_url).to_s
        quickstart_links = {
          "LIST_QUICKSTARTS"   => Link.new("List quickstarts", "GET", URI::join(base_url, "v1/quickstarts/promoted.json")),
          "SHOW_QUICKSTART"    => Link.new("Retrieve quickstart with :id", "GET", URI::join(base_url, "v1/quickstarts/:id"), [
            Param.new(":id", "string", "Unique identifier of the quickstart", nil, [])
          ]),
          "SEARCH_QUICKSTARTS" => Link.new("Search quickstarts", "GET", URI::join(base_url, "v1/quickstarts.json"), [
            Param.new("search", "string", "The search term to use for the quickstart", nil, [])
          ]),
        }
        links.merge! quickstart_links
      end
    end
    
    @reply = RestReply.new(:ok, "links", links)
    respond_with @reply, :status => @reply.status
  end
  
  protected
  
  def authenticate
    login = nil
    password = nil
    
    if request.headers['User-Agent'] == "OpenShift"
      if params['broker_auth_key'] && params['broker_auth_iv']
        login = params['broker_auth_key']
        password = params['broker_auth_iv']
      else  
        if request.headers['broker_auth_key'] && request.headers['broker_auth_iv']
          login = request.headers['broker_auth_key']
          password = request.headers['broker_auth_iv']
        end
      end
    end
    if login.nil? or password.nil?
      authenticate_with_http_basic { |u, p|
        login = u
        password = p
      }
    end      
    begin
      auth = OpenShift::AuthService.instance.authenticate(request, login, password)
      @login = auth[:username]
      @auth_method = auth[:auth_method]

      if not request.headers["X-Impersonate-User"].nil?
        subuser_name = request.headers["X-Impersonate-User"]

        if CloudUser.where(login: @login).exists?
          @parent_user = CloudUser.find_by(login: @login)
        else
          Rails.logger.debug "#{@login} tried to impersonate user but #{@login} user does not exist"
          raise OpenShift::AccessDeniedException.new "Insufficient privileges to access user #{subuser_name}"
        end

        parent_capabilities = @parent_user.get_capabilities
        if parent_capabilities.nil? || !parent_capabilities["subaccounts"] == true
          Rails.logger.debug "#{@parent_user.login} tried to impersonate user but does not have require capability."
          raise OpenShift::AccessDeniedException.new "Insufficient privileges to access user #{subuser_name}"
        end        

        if CloudUser.where(login: subuser_name).exists?
          subuser = CloudUser.find_by(login: subuser_name)
          if subuser.parent_user_id != @parent_user._id
            Rails.logger.debug "#{@parent_user.login} tried to impersinate user #{subuser_name} but does not own the subaccount."
            raise OpenShift::AccessDeniedException.new "Insufficient privileges to access user #{subuser_name}"
          end
          @cloud_user = subuser
        else
          Rails.logger.debug "Adding user #{subuser_name} as sub user of #{@parent_user.login} ...inside base_controller"
          @cloud_user = CloudUser.new(login: subuser_name, parent_user_id: @parent_user._id)
          init_user
        end
      else
        begin
          @cloud_user = CloudUser.find_by(login: @login)
        rescue Mongoid::Errors::DocumentNotFound
          Rails.logger.debug "Adding user #{@login}...inside base_controller"
          @cloud_user = CloudUser.new(login: @login)
          init_user
        end
      end

      log_actions_as(@cloud_user)
      @cloud_user.auth_method = @auth_method unless @cloud_user.nil?
    rescue OpenShift::UserException => e
      render_exception(e)
    rescue OpenShift::AccessDeniedException
      log_action_for(login, nil, "AUTHENTICATE", true, "Access denied", get_extra_log_args)
      request_http_basic_authentication
    end
  end
  
  def init_user
    begin
      @cloud_user.save
      Lock.create_lock(@cloud_user)
    rescue Moped::Errors::OperationFailure => e
      cu = CloudUser.find_by(login: @cloud_user.login)
      raise unless cu && (@cloud_user.parent_user_id == cu.parent_user_id)
      @cloud_user = cu
    end
  end

  def rest_replies_url(*args)
    return "/broker/rest/api"
  end
  
  def get_url
    #Rails.logger.debug "Request URL: #{request.url}"
    url = URI::join(request.url, "/broker/rest/")
    #Rails.logger.debug "Request URL: #{url.to_s}"
    return url.to_s
  end

  def nolinks
    get_bool(params[:nolinks])
  end
  
  def check_nolinks
    begin
      nolinks
    rescue Exception => e
      return render_exception(e)
    end
  end
 
  def check_version
    accept_header = request.headers['Accept']
    Rails.logger.debug accept_header    
    mime_types = accept_header ? accept_header.split(%r{,\s*}) : []
    version_header = API_VERSION
    mime_types.each do |mime_type|
      values = mime_type.split(%r{;\s*})
      values.each do |value|
        value = value.downcase
        if value.include?("version")
          version_header = value.split("=")[1].delete(' ').to_f
        end
      end
    end
    
    #$requested_api_version = request.headers['X_API_VERSION'] 
    if not version_header
      $requested_api_version = API_VERSION
    else
      $requested_api_version = version_header
    end
    
    if not SUPPORTED_API_VERSIONS.include? $requested_api_version
      invalid_version = $requested_api_version
      $requested_api_version = API_VERSION
      return render_error(:not_acceptable, "Requested API version #{invalid_version} is not supported. Supported versions are #{SUPPORTED_API_VERSIONS.map{|v| v.to_s}.join(",")}")
    end
  end

  def get_bool(param_value)
    return false unless param_value
    if param_value.is_a? TrueClass or param_value.is_a? FalseClass
      return param_value
    elsif param_value.is_a? String and param_value.upcase == "TRUE"
      return true
    elsif param_value.is_a? String and param_value.upcase == "FALSE"
      return false
    end
    raise OpenShift::OOException.new("Invalid value '#{param_value}'. Valid options: [true, false]", 167)
  end

  def get_extra_log_args
    args = {}
    args["APP"] = @application_name if @application_name
    args["DOMAIN"] = @domain_name if @domain_name
    args["APP_UUID"] = @application_uuid if @application_uuid
    return args
  end
  
  # Process all validation errors on a model and returns an array of message objects.
  #
  # == Parameters:
  #  object::
  #    MongoId model to process
  #  field_name_map::
  #    Maps an internal field name to a user visible field name. (Optional)
  def get_error_messages(object, field_name_map={})
    messages = []
    object.errors.keys.each do |key|
      field = field_name_map[key.to_s] || key.to_s
      err_msgs = object.errors.get(key)
      err_msgs.each do |err_msg|
        messages.push(Message.new(:error, err_msg, object.class.validation_map[key], field))
      end if err_msgs
    end if object && object.errors && object.errors.keys
    return messages
  end
  
  # Renders a REST response for an unsuccessful request.
  #
  # == Parameters:
  #  status::
  #    HTTP Success code. See {ActionController::StatusCodes::SYMBOL_TO_STATUS_CODE}
  #  msg::
  #    The error message returned in the REST response
  #  err_code::
  #    Error code for the message in the REST response
  #  log_tag::
  #    Tag used in action logs
  #  field::
  #    Specified the field (if any) that the message applies to.
  #  msg_type::
  #    Can be one of :error, :warning, :info. Defaults to :error
  #  messages::
  #    Array of message objects. If provided, it will log all messages in the action log and will add them to the REST response.
  #    msg,  err_code, field, and msg_type will be ignored.
  def render_error(status, msg, err_code=nil, log_tag=nil, field=nil, msg_type=nil, messages=nil, internal_error=false)
    reply = RestReply.new(status)
    if messages && !messages.empty?
      reply.messages.concat(messages)
      if log_tag
        log_msg = []
        messages.each { |msg| log_msg.push(msg.text) }
        log_action(log_tag, !internal_error, log_msg.join(', '), get_extra_log_args)
      end
    else
      msg_type = :error unless msg_type
      reply.messages.push(Message.new(msg_type, msg, err_code, field)) if msg
      log_action(log_tag, !internal_error, msg, get_extra_log_args) if log_tag
    end
    respond_with reply, :status => reply.status
  end
  
  # Renders a REST response for an exception.
  #
  # == Parameters:
  #  ex::
  #    The exception to return to the user.
  #  log_tag::
  #    Tag used in action logs
  def render_exception(ex, log_tag=nil)
    Rails.logger.error "Reference ID: #{request.uuid} - #{ex.message}\n  #{ex.backtrace.join("\n  ")}"
    error_code = ex.respond_to?('code') ? ex.code : 1
    message = ex.message
    if ex.kind_of? OpenShift::UserException
      status = :unprocessable_entity
    elsif ex.kind_of? OpenShift::DNSException
      status = :service_unavailable
    elsif ex.kind_of? OpenShift::NodeException
      status = :internal_server_error
      if ex.resultIO
        error_code = ex.resultIO.exitcode
        message = ""
        if ex.resultIO.errorIO && ex.resultIO.errorIO.length > 0
          message = ex.resultIO.errorIO.string.strip
        end
        message ||= ""
        message += "\nReference ID: #{request.uuid}"
      end
    else
      status = :internal_server_error
    end

    internal_error = status != :unprocessable_entity
    render_error(status, message, error_code, log_tag, nil, nil, nil, internal_error)
  end

  # Renders a REST response with for a succesful request.
  #
  # == Parameters:
  #  status::
  #    HTTP Success code. See {ActionController::StatusCodes::SYMBOL_TO_STATUS_CODE}
  #  type::
  #    Rest object type.
  #  data::
  #    REST Object to render
  #  log_tag::
  #    Tag used in action logs
  #  log_msg::
  #    Message to be logges in action logs
  #  publish_msg::
  #    If true, adds a message object to the REST response with type=>msg_type and message=>log_msg
  #  msg_type::
  #    Can be one of :error, :warning, :info. Defaults to :error
  #  messages::
  #    Array of message objects. If provided, it will log all messages in the action log and will add them to the REST response.
  #    publish_msg, log_msg, and msg_type will be ignored.
  def render_success(status, type, data, log_tag, log_msg=nil, publish_msg=false, msg_type=nil, messages=nil)
    reply = RestReply.new(status, type, data)
    if messages && !messages.empty?
      reply.messages.concat(messages)
      if log_tag
        log_msg = []
        messages.each { |msg| log_msg.push(msg.text) }
        log_action(log_tag, true, log_msg.join(', '), get_extra_log_args)
      end
    else
      msg_type = :info unless msg_type
      reply.messages.push(Message.new(msg_type, log_msg)) if publish_msg && log_msg
      log_action(log_tag, true, log_msg, get_extra_log_args) if log_tag
    end
    respond_with reply, :status => reply.status
  end
end
