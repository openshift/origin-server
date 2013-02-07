require 'pp'

begin
  require 'rspec/expectations'
  World(RSpec::Matchers)
  puts "Using RSpec 2"
rescue
  puts "Using RSpec 1"
end

AfterConfiguration do |config|
  SetupHelper::setup  
end
