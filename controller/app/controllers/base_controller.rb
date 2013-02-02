class BaseController < ActionController::Base
  before_filter :check_version, :only => :show
  before_filter :check_nolinks
  include OpenShift::Controller::ActionLog
  include OpenShift::Controller::ApiResponses
  include OpenShift::Controller::ApiBehavior
  #Mongoid.logger.level = Logger::WARN
  #Moped.logger.level = Logger::WARN
  
  # Initialize domain/app variables to be used for logging in user_action.log
  # The values will be set in the controllers handling the requests
  @domain_name = nil
  @application_name = nil
  @application_uuid = nil
  
  before_filter :set_locale

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
end
