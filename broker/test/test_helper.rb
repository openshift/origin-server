require File.expand_path('../coverage_helper.rb', __FILE__)

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha/setup'

def register_user(login=nil, password=nil)
  if ENV['REGISTER_USER']
    if File.exists?("/etc/openshift/plugins.d/openshift-origin-auth-remote-user.conf")
      `/usr/bin/htpasswd -b /etc/openshift/htpasswd #{login} #{password} > /dev/null 2>&1`
    else
      accnt = UserAccount.new(user: login, password: password)
      accnt.save
    end
  end
end

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
