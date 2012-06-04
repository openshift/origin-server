require 'active_resource/http_mock'

# Duplicate of ActiveResource::HttpMock method
class ActiveResource::PersistentConnection
  private
    silence_warnings do
      def http
        @http ||= ActiveResource::HttpMock.new(@site)
      end
    end
end

class ActiveResource::HttpMock
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
