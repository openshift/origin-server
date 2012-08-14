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
  API_VERSION = 1.1
  SUPPORTED_API_VERSIONS = [1.0,1.1]

  include UserActionLogger
  
  def show
    blacklisted_words = StickShift::ApplicationContainerProxy.get_blacklisted
    links = {
      "API" => Link.new("API entry point", "GET", URI::join(get_url, "api")),
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
        @parent_user = CloudUser.find @login
        subuser_name = request.headers["X-Impersonate-User"]

        if @parent_user.nil?
          Rails.logger.debug "#{@login} tried to impersinate user but #{@login} user does not exist"
          raise StickShift::AccessDeniedException.new "Insufficient privileges to access user #{subuser_name}"
        end

        if @parent_user.capabilities.nil? || !@parent_user.capabilities["subaccounts"] == true
          Rails.logger.debug "#{@parent_user.login} tried to impersinate user but does not have require capability."
          raise StickShift::AccessDeniedException.new "Insufficient privileges to access user #{subuser_name}"
        end

        sub_user = CloudUser.find subuser_name
        if sub_user && sub_user.parent_user_login != @parent_user.login
          Rails.logger.debug "#{@parent_user.login} tried to impersinate user #{subuser_name} but does not own the subaccount."
          raise StickShift::AccessDeniedException.new "Insufficient privileges to access user #{subuser_name}"
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
      return ["true", "1"].include?(ignore_links)
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
      @reply = RestReply.new(:not_acceptable)
      @reply.messages.push(message = Message.new(:error, "Requested API version #{invalid_version} is not supported.  Supported versions are #{SUPPORTED_API_VERSIONS.map{|v| v.to_s}.join(",")}"))
      respond_with(@reply) do |format|
        format.xml { render :xml => @reply, :status => @reply.status }
        format.json { render :json => @reply, :status => @reply.status }
      end
      return
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

  def throw_error(status, msg, error_code, field=nil)
    @reply = RestReply.new(status)
    @reply.messages.push(message = Message.new(:error, msg, error_code, field))
    respond_with(@reply) do |format|
      format.xml { render :xml => @reply, :status => @reply.status }
      format.json { render :json => @reply, :status => @reply.status }
    end
  end
end
