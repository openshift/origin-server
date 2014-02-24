module AdminConsole
  module Api
    class ApiController < ActionController::Base
      include Rescue
      respond_to :json
      
      rescue_from Exception, :with => :render_exception

      MAX_RESULTS=100
      API_VERSION="1.0"

      protected
        class UnprocessableEntity < Exception
        end

        def raise_on_incompatible_parameters(param1, param2)
          raise UnprocessableEntity.new("Can not specify both the #{param1} and #{param2} parameters.") unless params[param1].blank? || params[param2].blank?
        end

        def render_exception(e)
          # For now we don't have specific codes
          response = {:error => {:code => "EX", :message => e.message}}
          status =  case e
                    when UnprocessableEntity
                      :unprocessable_entity
                    else
                      :server_error
                    end
          respond_with response, :status => status
        end

        def build_response(data, more=false)
          {
            :api_version => API_VERSION,
            :data => data,
            :more => more
          }
        end
    end
  end
end
