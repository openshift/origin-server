module OpenShift
  class RemoteUserAuthService
    # The base_controller will actually pass in a password but it can't be
    # trusted.  The trusted must only be set if the web server has verified the
    # password.
    def authenticate_request(controller)
      # FIXME: trusted_header i.e. 'REMOTE_USER' env var is missing for REST apis with singular resource format
      # Work-around is to rely on Thread.current[:user_action_log_identity_id] when trusted_header is not set
      # until we fix https://bugzilla.redhat.com/show_bug.cgi?id=1086910
      username = controller.request.env[trusted_header] || Thread.current[:user_action_log_identity_id]
      raise OpenShift::AccessDeniedException if username.blank?
      {:username => username}
    end

    protected
      def trusted_header
        Rails.configuration.auth[:trusted_header]
      end
  end
end
