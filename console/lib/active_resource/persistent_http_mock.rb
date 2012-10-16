#
# When this module is included it will prevent normal ActiveResource calls from being made.  Be sure to
# use ActiveSupport::Testing::Isolation and require this module in the setup method if you want to use
# ActiveResource::HttpMock in the same test suite that hits the server.
#
require 'active_resource/http_mock'

# Duplicate of ActiveResource::HttpMock method
class ActiveResource::PersistentConnection
  private
    silence_warnings do
      alias_method :http_without_mock, :http
      # changes behavior, will not cache http object
      def http
        if ActiveResource::HttpMock.enabled?
          ActiveResource::HttpMock.new(@site)
        else
          http_without_mock
        end
      end
    end
end

class ActiveResource::HttpMock
  def self.enabled=(bool)
    @enabled = bool
  end
  def self.enabled?
    @enabled
  end
  def request(uri, req)
    headers = {}
    req.each_capitalized{ |k,v| headers[k] = v unless k == 'Accept' && v == '*/*' }
    request = ActiveResource::Request.new(req.method.downcase.to_sym, req.path, req.request_body_permitted? ? req.body : nil, headers)
    self.class.requests << request
    if response = self.class.responses.assoc(request)
      response[1]
    else
      raise ActiveResource::InvalidRequestError.new("Could not find a response recorded for\n  #{request.inspect}\n - Responses recorded are:\n  #{self.class.responses.map{|r| r.inspect}.join("\n  ")}")
    end
  end
end

# Add PATCH support
class ActiveResource::HttpMock::Responder
  def patch(path, request_headers = {}, body = nil, status = 200, response_headers = {})
    request  = ActiveResource::Request.new(:patch, path, nil, request_headers)
    response = ActiveResource::Response.new(body || "", status, response_headers)

    delete_duplicate_responses(request)

    @responses << [request, response]
  end
end
class ActiveResource::HttpMock
  class << self 
    def patch(path, body, headers)
      request = ActiveResource::Request.new(:patch, path, body, headers)
      self.class.requests << request
      if response = self.class.responses.assoc(request)
        response[1]
      else
        raise InvalidRequestError.new("Could not find a response recorded for \#{request.to_s} - Responses recorded are: \#{inspect_responses}")
      end
    end
  end
end

