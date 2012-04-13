#
# The simplest possible security strategy - this controller mixin
# will challenge the user with BASIC authentication, pass that
# information to the broker, and then cache the ticket and the user
# identifier in the session until the ticket expires.
#
module Console::Auth::Passthrough

  class PassthroughUser < RestApi::Authorization
    def initialize(opts={})
      opts.each_pair { |key,value| instance_variable_set("@#{key}", value) }
    end
  end

  def self.included(base)
    base.extend(self)
  end

  # return the current authenticated user or nil
  def session_user
    @authenticated_user
  end

  # This method should test authentication and handle if the user
  # is unauthenticated
  def require_login
    authenticate_or_request_with_http_basic('somewhere') do |login,password|
      if login.present?
        session_user = PassthroughUser.new :login => login, :password => password
      else
        raise Console::AccessDenied
      end
    end
  end

  def logged_in?
    not session_user.nil?
  end

  private
    def session_user=(user)
      @authenticated_user = user
    end
end
