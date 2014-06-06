# OS independent path locations
lib_dir  = File.join(File.join("lib", "**"), "*")
test_dir  = File.join(File.join("test", "**"), "*")
spec_file = "rubygem-openshift-origin-common.spec"

# Check for rails version, default to 3
begin
  require 'rails'
  rails_ver = Rails.version.to_i
rescue
  rails_ver = 3
end

Gem::Specification.new do |s|
  spec_file = IO.read(File.expand_path("../rubygem-#{File.basename(__FILE__, '.gemspec')}.spec", __FILE__))

  s.name        = "openshift-origin-common"
  s.version     = spec_file.match(/^Version:\s*(.*?)$/mi)[1].chomp
  s.authors     = ["Krishna Raman"]
  s.email       = ["kraman@gmail.com"]
  s.homepage    = 'https://github.com/openshift/origin-server'
  s.summary     = 'OpenShift Origin common'
  s.description = 'Core code for OpenShift Origin server components'

  s.files       = Dir[lib_dir] + Dir[test_dir]
  s.files       += %w(README.md Rakefile Gemfile rubygem-openshift-origin-common.spec openshift-origin-common.gemspec LICENSE COPYRIGHT)
  s.require_paths = ["lib"]

  s.add_dependency("json")
  s.add_dependency('safe_yaml')
  s.add_dependency("activemodel")
  s.add_dependency("rails-observers") if rails_ver > 3


  s.add_development_dependency('rspec', "1.1.12")
  s.add_development_dependency('mocha', "0.9.8")
  s.add_development_dependency('rake', '>= 0.8.7', '<= 0.9.6')
end
