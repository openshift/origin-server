require 'helpers/rest/api_v1'
require 'restclient'
require 'base64'

REST_CALLS = [ 
               REST_CALLS_V1
             ]

$end_point = "https://localhost/broker/rest"
$user = 'test-user' + gen_uuid[0..9]
$password = 'nopass'
$credentials = Base64.encode64("#{$user}:#{$password}")
$default_timeout = 120 # 120 secs

def register_user
  cmd = "ss-register-user -u #{$user} -p #{$password}"
  pid, stdin, stdout, stderr = nil, nil, nil, nil

  Bundler.with_clean_env {
    pid, stdin, stdout, stderr = Open4::popen4(cmd)
    stdin.close
    ignored, status = Process::waitpid2 pid
#    exitcode = status.exitstatus
  }
end

def http_call(api)
  timeout = api.request_timeout || $default_timeout
  headers = {}
  headers["Authorization"] = "Basic #{$credentials}"
  if api.version
    headers["Accept"] = "application/json; version=" + api.version
  else
    headers["Accept"] = "application/json"
  end
  request = RestClient::Request.new(:url => ($end_point + api.uri), :method => api.method, 
                                    :headers => headers, :payload => api.request, :timeout => timeout)
  begin
    response = request.execute
  rescue RestClient::ExceptionWithResponse => e
    puts e.response
    raise e
  end
  response
end
