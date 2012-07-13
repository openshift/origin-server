#
# When this module is included it will prevent normal ActiveResource calls from being made.  Be sure to
# use ActiveSupport::Testing::Isolation and require this module in the setup method if you want to use
# ActiveResource::HttpMock in the same test suite that hits the server.
#
require 'active_resource/http_mock'

# Duplicate of ActiveResource::HttpMock method
class ActiveResource::PersistentConnection
  protected
    silence_warnings do
      # changes behavior, will not cache http object
      def http_with_mock
        if ActiveResource::HttpMock.enabled?
          ActiveResource::HttpMock.new(@site)
        else
          http_without_mock
        end
      end
      alias_method_chain :http, :mock
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
