module OpenShift
  module Controller
    module OAuth
      extend self

      module ControllerMethods
        extend ActiveSupport::Concern

        def authenticate_with_bearer_token(&login_procedure)
          OAuth.authenticate(self, &login_procedure)
        end

        def request_http_bearer_token_authentication(error, error_description=nil)
          OAuth.authentication_request(self, error, error_description)
        end
      end

      def authenticate(controller, &login_procedure)
        bearer_token = token(controller)
        unless bearer_token.blank?
          login_procedure.call(bearer_token)
        end
      end

      def token(controller)
        if controller.request.authorization.to_s[/^Bearer (.*)/]
          bearer_token = $1.strip
        end

        if controller.respond_to? :bearer_token_override
          bearer_token = controller.send :bearer_token_override, bearer_token
        end

        bearer_token
      end

      def authentication_request(controller, error, error_description=nil)
        controller.headers["WWW-Authenticate"] = %(Bearer error="#{error.to_s.gsub(/"/, "")}"#{error_description.present? && " \"#{error_description.gsub(/"/, "")}"}")
        controller.__send__ :render, :text => "HTTP Bearer: Access denied.\n", :status => :unauthorized
      end
    end
  end
end
