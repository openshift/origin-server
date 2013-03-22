ENV['RAILS_ENV'] = 'test'
require "dummy/config/environment"
require "rails/test_help"
require "rubygems"
require "mocha"

def initialize_database() 
  sh "/usr/bin/mongo localhost/openshift_origin_broker_test --eval 'db.addUser(\"openshift\", \"mooo\")'"
end
