module OpenShift
  class RemoteUserAuthService
    # The base_controller will actually pass in a password but it can't be
    # trusted.  The trusted must only be set if the web server has verified the
    # password.
    def authenticate_request(controller)
      username = controller.request.env[trusted_header]
      raise OpenShift::AccessDeniedException if username.blank?
      {:username => username}
    end

    protected
      def trusted_header
        Rails.configuration.auth[:trusted_header]
      end
  end
end
