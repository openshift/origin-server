module OpenShift
  module Controller
    module Authentication
      extend ActiveSupport::Concern

      included do
        include OpenShift::Controller::OAuth::ControllerMethods
        helper_method :current_user, :user_signed_in?
      end

      protected
        #
        # Return the currently authenticated user or nil
        #
        def current_user
          @cloud_user
        end
        #
        # True if the user is currently authenticated
        #
        def user_signed_in?
          current_user.present?
        end

        def current_user_scopes
          @current_user_scopes || Scope::NONE
        end

        #
        # Filter a request to require an authenticated user
        #
        # FIXME Handle exceptions more consistently, gracefully recover from misbehaving
        #  services
        def authenticate_user!
          optionally_authenticate_user!(true)
        end

        #
        # Optionally authenticates user for a given request
        # Params:
        # +require_auth+:: if true, force authentication if none provided.  if false, determine user if authorization information provided.
        def optionally_authenticate_user!(require_auth)
          user = @cloud_user

          created = false

          unless user

            #
            # Each authentication type may return nil if no auth info is present,
            # false if the user failed authentication (may optionally render a response),
            # or a Hash with the following keys:
            #
            #   :user
            #     If present, use this user as the current request.  The current_identity
            #     field on the user will be used as the current identity, and will not
            #     be persisted.
            #
            #   :username
            #   :provider (CURRENTLY IGNORED)
            #     A user unique identifier, and a scoping provider.  The default provider
            #     is nil. :username must be unique within the provider scope.
            #
            info = authentication_types.find{ |i| not i.nil? }

            return if response_body
            unless info && (info[:username].present? || info[:user].present?)
              request_http_basic_authentication if require_auth
              return
            end

            scopes = info[:scopes] || Scope::SESSION
            if info[:user]
              user = info[:user]
            else
              user, created = CloudUser.find_or_create_by_identity(info[:provider], info[:username])
              user = impersonate(user)
            end

            raise "Service did not set the user login attribute" unless user.login.present?

            user.auth_method = info[:auth_method] || :login
            user.scopes = @current_user_scopes = scopes
            @cloud_user = user
            log_actions_as(user)

            headers['X-OpenShift-Identity'] = user.login
            headers['X-OpenShift-Identity-Id'] = user._id.to_s
            headers['X-OAuth-Scopes'] = scopes

            log_action("AUTHENTICATE", nil, true, "Authenticated", 'IP' => request.remote_ip, 'SCOPES' => scopes)

            return unless check_controller_scopes
          end

          @analytics_tracker = OpenShift::AnalyticsTracker.new(request)
          @analytics_tracker.identify(user)
          @analytics_tracker.track_user_event('user_create', user) if created

          user

        rescue OpenShift::AccessDeniedException => e
          render_error(:unauthorized, e.message, 1) if require_auth
        end


        #
        # Attempt to locate a user by their credentials. No impersonation 
        # is allowed.
        #
        # This method is intended to be used from specific endpoints that
        # must challenge authentication with credentials only.  It is not
        # used at this time.
        #
        def authenticate_user_from_credentials(username, password)
          info =
            if auth_service.respond_to?(:authenticate) && auth_service.method(:authenticate).arity == 2
              auth_service.authenticate(username, password).tap do |info|
                log_action("CREDENTIAL_AUTHENTICATE", nil, true, "Access denied by auth service", {'IP' => request.remote_ip, 'LOGIN' => username}) unless info
              end
            end || nil

          if info
            raise "Authentication service must return a username with its response" if info[:username].nil?

            user, _ = CloudUser.find_or_create_by_identity(info[:provider], info[:username])
            log_action("CREDENTIAL_AUTHENTICATE", nil, true, "Authenticated via credentials", {'LOGIN' => username, 'IP' => request.remote_ip})
            user
          end
        rescue OpenShift::AccessDeniedException => e
          logger.debug "Service rejected credentials #{e.message} (#{e.class})\n  #{e.backtrace.join("\n  ")}"
          log_action("CREDENTIAL_AUTHENTICATE", nil, true, "Access denied by auth service", {'LOGIN' => username, 'IP' => request.remote_ip, 'ERROR' => e.message})
          nil
        end

        #
        # This should be abstracted to an OpenShift.config service implementation
        # that allows the product to easily reuse these without having to be exposed
        # as helpers.
        #
        def broker_key_auth
          @broker_key_auth ||= OpenShift::Auth::BrokerKey.new
        end
        # Same note as for broker_key_auth
        def auth_service
          @auth_service ||= OpenShift::AuthService.instance
        end

        def check_controller_scopes
          if current_user_scopes.empty?
            render_error(:forbidden, "You are not authorized to perform any operations.", 1)
            false
          elsif !current_user_scopes.any?{ |s| s.allows_action?(self) }
            render_error(:forbidden, "This action is not allowed with your current authorization.", 1)
            false
          else
            true
          end
        end

      private
        #
        # Lazily evaluate the authentication types on this class
        #
        def authentication_types
          Enumerator.new do |y|
            [
              :authenticate_broker_key,
              :authenticate_bearer_token,
              :authenticate_request_via_service,
              :authenticate_basic_via_service,
            ].each{ |sym| y.yield send(sym) }
          end
        end

        #
        # If broker key authentication was requested, validate it.
        #
        def authenticate_broker_key
          broker_key_auth.authenticate_request(self)
        rescue OpenShift::AccessDeniedException => e
          log_action("AUTHENTICATE", nil, false, "Access denied by broker key", {'IP' => request.remote_ip, 'ERROR' => e.message})
          false
        end

        #
        # If an HTTP Authorization Bearer header is provided, check against the 
        # authorization table for access.
        #
        def authenticate_bearer_token
          authenticate_with_bearer_token do |token|
            if auth = Authorization.authenticate(token)
              if auth.accessible?
                user = auth.user
                #user.current_identity = Identity.for('authorization_token', auth.id, auth.created_at)
                {:user => user, :auth_method => :authorization_token, :scopes => auth.scopes_list}
              else
                request_http_bearer_token_authentication(:invalid_token, 'The access token expired')
                log_action("AUTHENTICATE", nil, true, "Access denied by bearer token", {'TOKEN' => auth.token, 'IP' => request.remote_ip, 'FORBID' => 'expired'})
                false
              end
            else
              request_http_bearer_token_authentication(:invalid_token, 'The access token is not recognized')
              log_action("AUTHENTICATE", nil, true, "Access denied by bearer token", {'TOKEN' => token, 'IP' => request.remote_ip, 'FORBID' => 'does_not_exist'})
              false
            end
          end
        end

        #
        # If the authentication service supports full request authentication,
        # invoke it.
        #
        def authenticate_request_via_service
          return unless auth_service.respond_to? :authenticate_request

          auth_service.authenticate_request(self).tap do |info|
            if info == false || response_body
              log_action("AUTHENTICATE", nil, true, "Access denied by authenticate_request", {'IP' => request.remote_ip})
              return false
            end
          end
        rescue OpenShift::AccessDeniedException => e
          logger.debug "Service rejected request #{e.message} (#{e.class})\n  #{e.backtrace.join("\n  ")}"
          log_action("AUTHENTICATE", nil, true, "Access denied by authenticate_request", {'IP' => request.remote_ip, 'ERROR' => e.message})
          false
        end

        #
        # Given an HTTP Authorization: BASIC header, determine whether the user
        # credentials (if provided) are valid.
        #
        def authenticate_basic_via_service
          return unless auth_service.respond_to? :authenticate

          username = nil
          authenticate_with_http_basic do |u, p|
            next if u.blank?
            username = u
            if auth_service.method(:authenticate).arity == 2
              auth_service.authenticate(u, p)
            else
              #DEPRECATED - Will be removed in favor of #authenticate_request
              auth_service.authenticate(request, u, p)
            end
          end.tap do |info|
            if info == false
              log_action_for(username, nil, "AUTHENTICATE", nil, true, "Access denied by authenticate", {'IP' => request.remote_ip})
            end
          end
        rescue OpenShift::AccessDeniedException => e
          logger.debug "Service rejected credentials #{e.message} (#{e.class})\n  #{e.backtrace.join("\n  ")}"
          log_action_for(username, nil, "AUTHENTICATE", nil, true, "Access denied by authenticate", {'IP' => request.remote_ip, 'ERROR' => e.message})
          false
        end

        #
        # Given a user and a request, have the current user impersonate another.
        #
        def impersonate(user)
          other = request.headers["X-Impersonate-User"]
          return user unless other.present?

          unless user.capabilities['subaccounts'] == true
            log_action_for(user.login, user.id, "IMPERSONATE", nil, true, "Failed to impersonate", {'SUBJECT' => other, 'IP' => request.remote_ip, 'FORBID' => 'no_subaccount_capability'})
            raise OpenShift::AccessDeniedException, "Insufficient privileges to access user #{other}"
          end

          CloudUser.find_or_create_by_identity("impersonation/#{user.id}", other, parent_user_id: user.id) do |existing_user, existing_identity|
            if existing_user.parent_user_id != user.id
              log_action_for(user.login, user.id, "IMPERSONATE", nil, true, "Failed to impersonate", {'SUBJECT' => other, 'IP' => request.remote_ip, 'FORBID' => 'not_child_account'})
              raise OpenShift::AccessDeniedException, "Account is not associated with impersonate account #{other}"
            end
          end.first.tap do |other_user|
            log_action_for(user.login, user.id, "IMPERSONATE", nil, true, "Impersonation successful", {'SUBJECT_ID' => other_user.id})
          end
        end
    end
  end
end
