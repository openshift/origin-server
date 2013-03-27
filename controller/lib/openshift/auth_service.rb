module OpenShift
  ##
  # This class provides support to plugin different authentication providers.
  # It should also be used as the Base class from which other Authentication plugins inherit.
  class AuthService
    ##
    # Default provider is this base class. It is a pass-through implementation that accepts any
    # username/password combination.
    @oo_auth_provider = OpenShift::AuthService

    ##
    # Switch the Authentication plugin class.
    #
    # @param provider_class [Class] Class that extends OpenShift::AuthService and provides an authentication plugin.
    def self.provider=(provider_class)
      @oo_auth_provider = provider_class
    end

    def self.instance
      @oo_auth_provider.new
    end

    ##
    # Authenticate a user/password pair
    #
    # @param login [String] - Login name of the user
    # @param password [String] - Password of the user
    # @return [Hash, false, nil] Returns one of:
    #   * {
    #      :username => <An instance of CloudUser (retrieved via the model)>
    #     }
    #   * {
    #      :username => <the unique identifier of this user>,
    #      :provider => (optional) <a scope under which this username is unique>
    #     }
    #   * false or nil indicating authentication failure.
    def authenticate(login, password)
      {:username => login}
    end

    ##
    # The authenticate_request method *MAY* be implemented. This method can be used
    # if you need access to the Rails request to determine authentication, such as
    # the ability to read a cookie.
    #
    # NOTE: If you implement cookie support, you must ALSO enable CSRF protection 
    # in the console and the broker. By default the broker requires no forgery
    # protection.
    #
    # Implementors may write to the response to signal to a client that the 
    # request has failed, in which case authentication will be denied.
    #
    # @param controller [BaseController] Controller against which the request is 
    #    being run. It can be used to retrieve the request and associated environment
    #    Eg: controller.request.env["FOO"]
    # @return [Hash, false, nil] Returns one of:
    #   * {
    #      :username => <An instance of CloudUser (retrieved via the model)>
    #     }
    #   * {
    #      :username => <the unique identifier of this user>,
    #      :provider => (optional) <a scope under which this username is unique>
    #     }
    #   * false or nil indicating authentication failure.
    def authenticate_request(controller)
    end
  end
end
