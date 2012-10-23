require 'rubygems'
require 'openshift-origin-controller'
require 'date'

module OpenShift
  class RemoteUserAuthService < OpenShift::AuthService

    def initialize
      super

      @trusted_header = @auth_info[:trusted_header]
    end

    # The base_controller will actually pass in a password but it can't be
    # trusted.  REMOTE_USER must only be set if the web server has verified the
    # password.
    def authenticate(request, login=nil, password=nil)
      if request.headers['User-Agent'] == "OpenShift"
        # password == iv, login == key
        return validate_broker_key(password, login)
      else
        authenticated_user = request.env[@trusted_header]
        raise OpenShift::AccessDeniedException if authenticated_user.nil?
        return {:username => authenticated_user, :auth_method => :login}
      end
    end

    # This is only called by the legacy controller and should be removed as
    # soon as all clients have been ported.
    def login(request, params, cookies)
      if params['broker_auth_key'] && params['broker_auth_iv']
        return validate_broker_key(params['broker_auth_iv'], params['broker_auth_key'])
      else
        username = request.env[@trusted_header]
        Rails.logger.debug("Found" + username)
        return authenticate(request, username)
      end
    end
  end
end
