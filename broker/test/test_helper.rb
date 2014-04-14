require File.expand_path('../coverage_helper.rb', __FILE__)

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha/setup'

$auth_warn_once = false

def register_user(login=nil, password=nil, prod_env=false)
  if ENV['REGISTER_USER']
    if File.exists?("/etc/openshift/plugins.d/openshift-origin-auth-remote-user.conf")
      cmd = "/usr/bin/htpasswd -b /etc/openshift/htpasswd #{login} #{password}"
      with_clean_env do
        pid, stdin, stdout, stderr = Open4::popen4(cmd)
        stdin.close
        ignored, status = Process::waitpid2 pid
        #exitcode = status.exitstatus
      end
    else
      #ignore
      unless $auth_warn_once
        $auth_warn_once = true
        puts "Unknown auth plugin. Not registering user #{login}/#{password}. Modify #{__FILE__} if user registration is required."
      end
    end
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

# Load support files
Dir["#{OpenShift::CloudEngine.root}/test/support/**/*.rb",
    "#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
