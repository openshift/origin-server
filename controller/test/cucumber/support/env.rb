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

Before do 
 if !(@test_apps_hash.nil?)
     @test_apps_hash.each do |app_name_key, app|
         rhc_ctl_destroy(app)
     end
 else
    $logger.info("No apps to delete. The hash of TestApps is empty")
 end
 @test_apps_hash = {}
 @unique_namespace_apps_hash = {}

end
