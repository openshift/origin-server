ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha'
#require 'crankcase-mongo-plugin'

def gen_uuid
  %x[/usr/bin/uuidgen].gsub('-', '').strip 
end
