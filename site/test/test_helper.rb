ENV["RAILS_ENV"] = "test"

require File.expand_path("../../config/environment.rb",  __FILE__)
require "rails/test_help"

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{Console::Engine.root}/test/support/**/*.rb",
    "#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
