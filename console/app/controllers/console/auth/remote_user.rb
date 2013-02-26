#
# The simplest possible security strategy - this controller mixin
# will look for user info as a header on the request, and pass that
# info down to the broker.  The broker should be configured to 
# authenticate with those headers.
# 
module Console::Auth::RemoteUser
  extend ActiveSupport::Concern

  class RemoteUser < RestApi::Credentials
    extend ActiveModel::Naming
    include ActiveModel::Conversion

    def initialize(username, headers)
      @username = username
      @headers = headers.freeze
    end
    def login
      @username
    end
    def email_address
      nil
    end
    def to_headers
      @headers
    end
    def persisted?
      false
    end
  end

  included do
    helper_method :current_user, :user_signed_in?, :previously_signed_in?

    rescue_from ActiveResource::UnauthorizedAccess, :with => :console_access_denied
  end

  # return the current authenticated user or nil
  def current_user
    @authenticated_user
  end

  # This method should test authentication and handle if the user
  # is unauthenticated
  def authenticate_user!
    @authenticated_user ||= begin
        name = request.env[Console.config.remote_user_header]
        raise Console::AccessDenied unless name
        display_name = request.env[Console.config.remote_user_name_header] unless Console.config.remote_user_name_header.nil?
        name = display_name || name
        logger.debug "  Identified user #{name} from headers"
        RemoteUser.new(
          name,
          Console.config.remote_user_copy_headers.inject({}) do |h, name|
            value = request.headers[name]
            h[name] = value if value.present?
            h
          end)
      end
  end

  def user_signed_in?
    not current_user.nil?
  end

  def previously_signed_in?
    cookies[:prev_login] ? true : false
  end
end
