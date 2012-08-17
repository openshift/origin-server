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

class StickShift::Responder < ::ActionController::Responder
  def api_behavior(error)
    raise error unless resourceful?
    status = resource.each{ |r| break(r[:status]) if r.class == Hash && r.has_key?(:status) }
    display resource[0], status: status
  end
end

class BaseController < ApplicationController
  respond_to :json, :xml
  before_filter :check_version, :only => :show
  before_filter :check_nolinks
  API_VERSION = 1.1
  SUPPORTED_API_VERSIONS = [1.0,1.1]
  include UserActionLogger

  before_filter :set_locale
  def set_locale
    # if params[:locale] is nil then I18n.default_locale will be used
    I18n.locale = nil
  end

  # Override default Rails responder to return status code and objects from PUT/POST/DELETE requests
  def respond_with(*arguments)
    super(arguments, :responder => StickShift::Responder)
  end
  
  def show
    blacklisted_words = StickShift::ApplicationContainerProxy.get_blacklisted
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
    } unless nolinks
    
    @reply = RestReply.new(:ok, "links", links)
    respond_with @reply, :status => @reply.status
  end
  
  protected
  
  def gen_req_uuid
    # The request id can be generated differently to make it a bit more meaningful
    File.open("/proc/sys/kernel/random/uuid", "r") do |file|
      file.gets.strip.gsub("-","")
    end
  end
  
  def authenticate
    login = nil
    password = nil
    @request_id = gen_req_uuid

    if request.headers['User-Agent'] == "StickShift"
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
      auth = StickShift::AuthService.instance.authenticate(request, login, password)
      @login = auth[:username]
      @auth_method = auth[:auth_method]

      if not request.headers["X-Impersonate-User"].nil?
        @parent_user = CloudUser.find_by(login: @login)
        subuser_name = request.headers["X-Impersonate-User"]

        if @parent_user.nil?
          Rails.logger.debug "#{@login} tried to impersinate user but #{@login} user does not exist"
          raise StickShift::AccessDeniedException.new "Insufficient privileges to access user #{subuser_name}"
        end

        if @parent_user.capabilities.nil? || !@parent_user.capabilities["subaccounts"] == true
          Rails.logger.debug "#{@parent_user.login} tried to impersinate user but does not have require capability."
          raise StickShift::AccessDeniedException.new "Insufficient privileges to access user #{subuser_name}"
        end

        sub_user = CloudUser.find_by(login: subuser_name)
        if sub_user && sub_user.parent_user_login != @parent_user.login
          Rails.logger.debug "#{@parent_user.login} tried to impersinate user #{subuser_name} but does not own the subaccount."
          raise StickShift::AccessDeniedException.new "Insufficient privileges to access user #{subuser_name}"
        end

        if sub_user.nil?
          Rails.logger.debug "Adding user #{subuser_name} as sub user of #{@parent_user.login} ...inside base_controller"
          @cloud_user = CloudUser.new(login: subuser_name, parent_user_id: @parent_user._id)
          ###TODO: inherit capabilities?
          @cloud_user.save
        else
          @cloud_user = sub_user
        end
      else
        begin
          @cloud_user = CloudUser.find_by(login: @login)
        rescue Mongoid::Errors::DocumentNotFound
          Rails.logger.debug "Adding user #{@login}...inside base_controller"
          @cloud_user = CloudUser.new(login: @login)
          @cloud_user.save
        end
      end
      
      @cloud_user.auth_method = @auth_method unless @cloud_user.nil?
    rescue StickShift::AccessDeniedException
      log_action(@request_id, 'nil', login, "AUTHENTICATE", false, "Access denied")
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
  
  def rest_reply_url(*args)
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
      raise StickShift::UserException.new("Invalid value for 'nolinks'. Valid options: [true, false, 1, 0]", 167)
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
 
  def get_cloud_user_info(cloud_user)
    if cloud_user
      return { :uuid  => cloud_user._id.to_s, :login => cloud_user.login }
    else
      return { :uuid  => 0, :login => 'anonymous' }
    end
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

  # Renders a REST response for an unsuccesful request.
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
  def render_error(status, msg, err_code=nil, log_tag=nil, field=nil, msg_type=nil, messages=nil)
    reply = RestReply.new(status)
    user_info = get_cloud_user_info(@cloud_user)
    if messages && !messages.empty?
      reply.messages.concat(messages)
      if log_tag
        log_msg = []
        messages.each { |msg| log_msg.push(msg.text) }
        log_action(@request_id, user_info[:uuid], user_info[:login], log_tag, false, log_msg.join(', '))
      end
    else
      msg_type = :error unless msg_type
      reply.messages.push(Message.new(msg_type, msg, err_code, field)) if msg
      log_action(@request_id, user_info[:uuid], user_info[:login], log_tag, false, msg) if log_tag
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
    Rails.logger.error ex
    Rails.logger.error ex.backtrace
    error_code = ex.respond_to?('code') ? ex.code : 1
    if ex.kind_of? StickShift::UserException
      status = :unprocessable_entity
    elsif ex.kind_of? StickShift::DNSException
      status = :service_unavailable
    else
      status = :internal_server_error
    end
    render_error(status, ex.message, error_code, log_tag, nil, nil, nil)
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
    user_info = get_cloud_user_info(@cloud_user)
    if messages && !messages.empty?
      reply.messages.concat(messages)
      if log_tag
        log_msg = []
        messages.each { |msg| log_msg.push(msg.text) }
        log_action(@request_id, user_info[:uuid], user_info[:login], log_tag, true, log_msg.join(', '))
      end
    else
      msg_type = :info unless msg_type
      reply.messages.push(Message.new(msg_type, log_msg)) if publish_msg && log_msg
      log_action(@request_id, user_info[:uuid], user_info[:login], log_tag, true, log_msg) if log_tag
    end
    respond_with reply, :status => reply.status
  end
end
