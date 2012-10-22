require 'openshift-origin-common'
unless ENV["RAILS_ENV"] == "test"
  if File.exist?(File.join(OpenShift::Config::CONF_DIR, 'development'))
    ENV["RAILS_ENV"] = "development"
  else
    ENV["RAILS_ENV"] = "production"
  end
end

# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Broker::Application.initialize!
