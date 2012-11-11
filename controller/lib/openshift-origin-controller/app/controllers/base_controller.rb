require 'action_dispatch/http/mime_types'
module Mime
  class Type
    class << self
      def lookup(string)
         LOOKUP[string.split(';').first]
       end
    end
  end
end
class BaseController < ActionController::Base
  respond_to :json, :xml
  before_filter :check_version, :only => :show
  before_filter :check_nolinks
  API_VERSION = 1.3
  SUPPORTED_API_VERSIONS = [1.0,1.1,1.2, 1.3]

  include UserActionLogger
  
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
        "LIST_CARTRIDGES" => Link.new("List cartridges", "GET", URI::join(get_url, "cartridges")),
        "LIST_TEMPLATES" => Link.new("List application templates", "GET", URI::join(get_url, "application_templates")),
        "LIST_ESTIMATES" => Link.new("List available estimates", "GET" , URI::join(get_url, "estimates"))
      }
      links.merge!(if base_url = Rails.application.config.openshift[:community_quickstarts_url]
        {
          "LIST_QUICKSTARTS"   => Link.new("List quickstarts", "GET", URI::join(base_url, "v1/quickstarts/promoted.json")),
          "SHOW_QUICKSTART"    => Link.new("Retrieve quickstart with :id", "GET", URI::join(base_url, "v1/quickstarts/:id"), [':id']),
          "SEARCH_QUICKSTARTS" => Link.new("Search quickstarts", "GET", URI::join(base_url, "v1/quickstarts.json"), ['search']),
        }
      else
        {
          "LIST_QUICKSTARTS"   => Link.new("List quickstarts", "GET", URI::join(get_url, "quickstarts")),
          "SHOW_QUICKSTART"    => Link.new("Retrieve quickstart with :id", "GET", URI::join(get_url, "quickstarts/:id"), [':id']),
        }
      end)
    end
    
    @reply = RestReply.new(:ok, "links", links)
    respond_with @reply, :status => @reply.status
  end
  
  protected
  
  def authenticate
    login = nil
    password = nil
    @request_id = gen_req_uuid

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
        @parent_user = CloudUser.find @login
        subuser_name = request.headers["X-Impersonate-User"]

        if @parent_user.nil?
          Rails.logger.debug "#{@login} tried to impersonate user but #{@login} user does not exist"
          raise OpenShift::AccessDeniedException.new "Insufficient privileges to access user #{subuser_name}"
        end

        if @parent_user.capabilities.nil? || !@parent_user.capabilities["subaccounts"] == true
          Rails.logger.debug "#{@parent_user.login} tried to impersonate user but does not have require capability."
          raise OpenShift::AccessDeniedException.new "Insufficient privileges to access user #{subuser_name}"
        end

        sub_user = CloudUser.find subuser_name
        if sub_user && sub_user.parent_user_login != @parent_user.login
          Rails.logger.debug "#{@parent_user.login} tried to impersinate user #{subuser_name} but does not own the subaccount."
          raise OpenShift::AccessDeniedException.new "Insufficient privileges to access user #{subuser_name}"
        end

        if sub_user.nil?
          Rails.logger.debug "Adding user #{subuser_name} as sub user of #{@parent_user.login} ...inside base_controller"
          @cloud_user = CloudUser.new(subuser_name,nil,nil,nil,{},@parent_user.login)
          @cloud_user.parent_user_login = @parent_user.login
          init_user
        else
          @cloud_user = sub_user
        end
      else
        @cloud_user = CloudUser.find @login
        if @cloud_user.nil?
          Rails.logger.debug "Adding user #{@login}...inside base_controller"
          @cloud_user = CloudUser.new(@login)
          init_user
        end
      end
      
      @cloud_user.auth_method = @auth_method unless @cloud_user.nil?
    rescue OpenShift::AccessDeniedException
      log_action(@request_id, 'nil', login, "AUTHENTICATE", true, "Access denied")
      request_http_basic_authentication
    end
  end

  def init_user()
    begin
      @cloud_user.save
    rescue Exception => e
      cu = CloudUser.find @login
      raise unless cu && (@cloud_user.parent_user_login == cu.parent_user_login)
      @cloud_user = cu
    end
  end

  def get_application(id)
    app = Application.find(@cloud_user, id)
    app.user_agent = request.headers['User-Agent'] if app
    app
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
    ignore_links = params[:nolinks]
    if ignore_links
      ignore_links.downcase!
      return true if ["true", "1"].include?(ignore_links)
      return false if ["false", "0"].include?(ignore_links)
      raise OpenShift::UserException.new("Invalid value for 'nolinks'. Valid options: [true, false, 1, 0]", 167)
    end
    return false
  end
 
  def check_version
    accept_header = request.headers['Accept']
    mime_types = accept_header.split(%r{,\s*})
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
      return render_format_error(:not_acceptable, "Requested API version #{invalid_version} is not supported. Supported versions are #{SUPPORTED_API_VERSIONS.map{|v| v.to_s}.join(",")}")
    end
  end

  def check_nolinks
    begin
      nolinks
    rescue Exception => e
      return render_format_exception(e)
    end
  end

  def get_bool(param_value)
    if param_value.is_a? TrueClass or param_value.is_a? FalseClass
      return param_value
    elsif param_value.is_a? String and param_value.upcase == "TRUE"
      return true
    else
      return false
    end
  end

  def gen_req_uuid
    # The request id can be generated differently to make it a bit more meaningful
    File.open("/proc/sys/kernel/random/uuid", "r") do |file|
      file.gets.strip.gsub("-","")
    end
  end
 
  def get_cloud_user_info(cloud_user)
    if cloud_user
      return { :uuid  => cloud_user.uuid, :login => cloud_user.login }
    else
      return { :uuid  => 0, :login => 'anonymous' }
    end
  end

  def get_error_messages(object, orig_field=nil, display_field=nil)
    messages = []
    object.errors.keys.each do |key|
      field = key.to_s
      field = display_field if orig_field && (key.to_s == orig_field)
      err_msgs = object.errors.get(key)
      err_msgs.each do |err_msg|
        messages.push(Message.new(:error, err_msg[:message], err_msg[:exit_code], field))
      end if err_msgs
    end if object && object.errors && object.errors.keys
    return messages
  end

  #Due to the bug in rails, 'format' is explicitly used for PUT, DELETE rest calls
  def render_response(reply, format=false)
    if format
      respond_with(reply) do |fmt|
        fmt.xml { render :xml => reply, :status => reply.status }
        fmt.json { render :json => reply, :status => reply.status }
      end
    else
      respond_with reply, :status => reply.status
    end
  end

  def render_error_internal(status, msg, err_code=nil, log_tag=nil,
                            field=nil, msg_type=nil, messages=nil, format=false)
    reply = RestReply.new(status)
    user_info = get_cloud_user_info(@cloud_user)

    logger_msg = nil
    if msg
      msg_type = :error unless msg_type
      reply.messages.push(Message.new(msg_type, msg, err_code, field))
      logger_msg = msg
    end
    if messages && !messages.empty?
      reply.messages.concat(messages)
      unless logger_msg
        msg = []
        messages.each { |m| msg.push(m.text) }
        logger_msg = msg.join(', ')
      end
    end
    log_action(@request_id, user_info[:uuid], user_info[:login], log_tag, false, logger_msg) if log_tag
    render_response(reply, format)
  end

  def render_exception_internal(ex, log_tag, format)
    Rails.logger.error ex
    Rails.logger.error ex.backtrace

    error_code = ex.respond_to?('code') ? ex.code : 1
    if ex.kind_of? OpenShift::UserException
      status = :unprocessable_entity
    elsif ex.kind_of? OpenShift::DNSException
      status = :service_unavailable
    else
      status = :internal_server_error
    end
    render_error_internal(status, ex.message, error_code, log_tag, nil, nil, nil, format)
  end

  def render_success_internal(status, type, data, log_tag, log_msg=nil, publish_msg=false,
                              msg_type=nil, messages=nil, format=false)
    reply = RestReply.new(status, type, data)
    user_info = get_cloud_user_info(@cloud_user)

    logger_msg = nil
    if log_msg
      msg_type = :info unless msg_type
      reply.messages.push(Message.new(msg_type, log_msg)) if publish_msg
      logger_msg = log_msg
    end
    if messages && !messages.empty?
      reply.messages.concat(messages)
      unless logger_msg
        msg = []
        messages.each { |m| msg.push(m.text) }
        logger_msg = msg.join(', ')
      end
    end
    log_action(@request_id, user_info[:uuid], user_info[:login], log_tag, true, logger_msg) if log_tag
    render_response(reply, format)
  end

  def render_format_error(status, msg, err_code=nil, log_tag=nil, field=nil, msg_type=nil, messages=nil)
    render_error_internal(status, msg, err_code, log_tag, field, msg_type, messages, true)
  end

  def render_format_exception(ex, log_tag=nil)
    render_exception_internal(ex, log_tag, true)
  end

  def render_format_success(status, type, data, log_tag, log_msg=nil, publish_msg=false, msg_type=nil, messages=nil)
    render_success_internal(status, type, data, log_tag, log_msg, publish_msg, msg_type, messages, true)
  end

  def render_error(status, msg, err_code=nil, log_tag=nil, field=nil, msg_type=nil, messages=nil)
    render_error_internal(status, msg, err_code, log_tag, field, msg_type, messages, false)
  end

  def render_exception(ex, log_tag=nil)
    render_exception_internal(ex, log_tag, false)
  end

  def render_success(status, type, data, log_tag, log_msg=nil, publish_msg=false, msg_type=nil, messages=nil)
    render_success_internal(status, type, data, log_tag, log_msg, publish_msg, msg_type, messages, false)
  end
end
