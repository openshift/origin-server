require 'helpers/rest/api_v1'
require 'restclient'
require 'base64'

REST_CALLS = [
               REST_CALLS_V1
             ]

hostname = "localhost"
begin
  if File.exists?("/etc/openshift/node.conf")
    config = ParseConfig.new("/etc/openshift/node.conf")
    val = config["PUBLIC_HOSTNAME"].gsub(/[ \t]*#[^\n]*/,"")
    val = val[1..-2] if val.start_with? "\""
    hostname = val
  end
rescue
  puts "Unable to determine hostname. Defaulting to localhost.\n"
end

$end_point = "https://#{hostname}/broker/rest"

$user = 'test-user' + gen_uuid[0..9]
$password = 'nopass'
$credentials = Base64.encode64("#{$user}:#{$password}")
$default_timeout = 120 # 120 secs

# openshift.com has its own authentication plugin for integrating with
# redhat.com
def registration_required?
  not hosted?
end

# openshift.com or Origin?
def hosted?
  cmd = "rpm -q rubygem-openshift-origin-auth-streamline"
  pid, stdin, stdout, stderr = nil, nil, nil, nil

  pid, stdin, stdout, stderr = Open4::popen4(cmd)
  stdin.close
  ignored, status = Process::waitpid2 pid

  status == 0
rescue
  puts "WARNING: Failed to check for hosted: #{$!}"
  false
end

def http_call(api, internal_test=false)
  timeout = api.request_timeout || $default_timeout

  if internal_test
    method = nil
    if api.method=="GET"
      method = :get
    elsif api.method=="POST"
      method = :post
    elsif api.method=="PUT"
      method = :put
    elsif api.method=="DELETE"
      method = :delete
    end
    if method
      headers = {}
      headers["HTTP_ACCEPT"] = "application/json" + (api.version ? "; version=#{api.version}" : "")
      headers["HTTP_AUTHORIZATION"] = "Basic #{$credentials}"
      headers["REMOTE_USER"] = $user
      request_via_redirect(method, "/broker/rest" + api.uri, api.request, headers)
      return @response.body.strip
    end
  else
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
    return response
  end

  return  nil
end
