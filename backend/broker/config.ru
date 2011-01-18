require 'rubygems'
require 'rack'
require 'json'
require 'libra'

class LibraService
  def call(env)
    status, body = case env['REQUEST_METHOD']
      when 'POST'
        # Parse the incoming data
        data = JSON.parse(Rack::Request.new(env).POST['json_data'])

        # Execute a framework cartridge
        Libra.execute(data['cartridge'], data['action'], data['app_name'], data['username'])

        # Just return a 200 success
        [200, "Success"]
      else
        # Only support POST requests right now
        [405, "Invalid method"]
    end

    [status, {'Content-Type' => 'text/html'}, body]
  end
end

run LibraService.new
