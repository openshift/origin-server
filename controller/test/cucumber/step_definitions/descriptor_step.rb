require 'rubygems'
require 'openshift-origin-controller'

  
When /^a descriptor file is provided$/ do
  @descriptor_file = File.expand_path("../misc/descriptor/manifest.yml", File.expand_path(File.dirname(__FILE__)))
end 
    
When /^the descriptor file is parsed as a cartridge$/ do
  f = File.open(@descriptor_file)
  @app = OpenShift::Cartridge.new.from_descriptor(YAML.load(f))
  f.close
end

Then /^the descriptor profile exists$/ do
  @app.default_profile.nil?.should be_false
end

Then /^atleast (\d+) group exists$/ do |count|
  len = @app.profiles[0].groups.length
  check = (len >= Integer(count))
  check.should be_true
end

Then /^atleast (\d+) component exists$/ do |count|
   g = @app.profiles[0].groups[0]
   comp = @app.profiles[0].components(g.component_refs[0].component)
   check = (not comp.nil?)
   check.should be_true
end


