require 'rubygems'
gemfile = File.expand_path('../../../../Gemfile', __FILE__)

require 'pry' if ENV['PRY']

if File.exist?(gemfile)
  ENV['BUNDLE_GEMFILE'] = gemfile
  require 'bundler'
  Bundler.setup
end

$:.unshift File.expand_path('../../../../lib', __FILE__)
