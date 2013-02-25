module OpenShift
  class AuthService
    @oo_auth_provider = OpenShift::AuthService

    def self.provider=(provider_class)
      @oo_auth_provider = provider_class
    end

    def self.instance
      @oo_auth_provider.new
    end

    #
    # The 3 argument version of this method authenticate(request,login,password) is 
    # deprecated.
    #
    # Authenticate a user/password pair. Returns:
    #
    #  nil/false if the authentication info is invalid
    #  A Hash containing the following keys if the info is valid:
    #
    #    :user - An instance of CloudUser (retrieved via the model)
    #
    #  OR
    #
    #    :username - the unique identifier of this user
    #    :provider (optional) - a scope under which this username is unique
    #
    #  If user is nil or username is blank or nil, authentication will
    #  be denied.
    #
    def authenticate(login, password)
      {:username => login}
    end

    #
    # The authenticate_request method MAY be implemented.  Use this method 
    # if you need access to the Rails request to determine authentication,
    # such as the ability to read a cookie.
    #
    # NOTE: If you implement cookie support, you must ALSO enable CSRF
    # protection in the console and the broker. By default the broker
    # requires no forgery protection.
    #
    # Implementors may write to the response to signal to a client that the 
    # request has failed, in which case authentication will be denied.
    #
    # Same return values as #authenticate(login,password)
    #
    # def authenticate_request(controller)
    # end
  end
end
