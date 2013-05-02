require 'rubygems'

unless ENV["RAILS_ENV"] == "test"
  if File.exist?('/etc/openshift/development')
    ENV["RAILS_ENV"] = "development"
  else
    ENV["RAILS_ENV"] = "production"
  end
end

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
