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
        bearer_token = token(controller.request)
        unless bearer_token.blank?
          login_procedure.call(bearer_token)
        end
      end

      def token(request)
        if request.authorization.to_s[/^Bearer (.*)/]
          $1.strip
        end
      end

      def authentication_request(controller, error, error_description=nil)
        controller.headers["WWW-Authenticate"] = %(Bearer error="#{error.to_s.gsub(/"/, "")}"#{error_description.present? && " \"#{error_description.gsub(/"/, "")}"}")
        controller.__send__ :render, :text => "HTTP Bearer: Access denied.\n", :status => :unauthorized
      end
    end
  end
end
