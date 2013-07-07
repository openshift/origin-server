# I wasn't able to get the tests to run in isolation without defining these
# constants
module Broker
  class Application
    def self.method_missing(meth, *args, &block)
      puts "Skipping #{meth}"
    end
  end
end

ENV['RAILS_ENV'] = 'test'
require "dummy/config/environment"
require "rails/test_help"
require "rubygems"
require "mocha/setup"
