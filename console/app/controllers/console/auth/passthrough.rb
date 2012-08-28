#
# The simplest possible security strategy - this controller mixin
# will challenge the user with BASIC authentication, pass that
# information to the broker, and then cache the ticket and the user
# identifier in the session until the ticket expires.
#
module Console::Auth::Passthrough
  extend ActiveSupport::Concern

  class PassthroughUser < RestApi::Authorization
    extend ActiveModel::Naming
    include ActiveModel::Conversion

    def initialize(opts={})
      opts.each_pair { |key,value| instance_variable_set("@#{key}", value) }
    end
    def email_address
      login
    end

    def persisted?
      false
    end
  end

  included do
    helper_method :current_user, :user_signed_in?, :previously_signed_in?
  end

  module InstanceMethods
    # return the current authenticated user or nil
    def current_user
      @authenticated_user
    end

    # This method should test authentication and handle if the user
    # is unauthenticated
    def authenticate_user!
      authenticate_or_request_with_http_basic("Authenticate to #{RestApi.site.host}") do |login,password|
        if login.present?
          @authenticated_user = PassthroughUser.new :login => login, :password => password
        else
          raise Console::AccessDenied
        end
      end
    end

    def user_signed_in?
      not current_user.nil?
    end

    def previously_signed_in?
      cookies[:prev_login] ? true : false
    end
  end
end
