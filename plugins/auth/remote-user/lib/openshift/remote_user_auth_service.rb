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
  end
end
