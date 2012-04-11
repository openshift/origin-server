ENV["RAILS_ENV"] = "test"
$:.unshift(File.dirname(__FILE__) + '/../../server-common')
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
