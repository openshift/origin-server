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

def register_user(prod_env=false)
  if File.exists?("/etc/openshift/plugins.d/openshift-origin-auth-mongo.conf")
    if prod_env
      `oo-register-user -l admin -p admin --username #{$user} --userpass #{$password}`
    else #test env
      uri = "/accounts"
      credentials = Base64.encode64("admin:admin")
      headers = {}
      headers["HTTP_ACCEPT"] = "application/json"
      headers["HTTP_AUTHORIZATION"] = "Basic #{credentials}"
      request_via_redirect(:post, "/broker/rest" + uri, {"username" => $user, "password" => $password}, headers)
    end
  elsif File.exists?("/etc/openshift/plugins.d/openshift-origin-auth-remote-user.conf")
    cmd = "/usr/bin/htpasswd -b /etc/openshift/htpasswd #{$user} #{$password}"
  else
    #ignore
    print "Unknown auth plugin. Not registering user #{$user}/#{$password}."
    print "Modify #{__FILE__}:36 if user registration is required."
    cmd = nil
  end
  pid, stdin, stdout, stderr = nil, nil, nil, nil

  if not cmd.nil?
    with_clean_env {
      pid, stdin, stdout, stderr = Open4::popen4(cmd)
      stdin.close
      ignored, status = Process::waitpid2 pid
#      exitcode = status.exitstatus
    }
  end
end

#From http://spectator.in/2011/01/28/bundler-in-subshells/
#
#We can revert to using Bundler.with_clean_env when Bundler 1.1.x hits Fedora
def with_clean_env
  bundled_env = ENV.to_hash
  %w(BUNDLE_GEMFILE RUBYOPT BUNDLE_BIN_PATH).each{ |var| ENV.delete(var) }
  yield
ensure
  ENV.replace(bundled_env.to_hash)
end

# openshift.com has it's own authentication plugin for integrating with
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
