# -*- encoding: utf-8 -*-
config_dir  = File.join(File.join("config", "**"), "*")
app_dir  = File.join(File.join("app", "**"), "*")
$:.push File.expand_path("../lib", __FILE__)
lib_dir  = File.join(File.join("lib", "**"), "*")
test_dir  = File.join(File.join("test", "**"), "*")
bin_dir  = File.join("bin","*")
conf_dir  = File.join(File.join("conf", "**"), "*")
spec_file = "rubygem-openshift-origin-auth-mongo.spec"

Gem::Specification.new do |s|
  spec_file = IO.read(File.expand_path("../rubygem-#{File.basename(__FILE__, '.gemspec')}.spec", __FILE__))

  s.name        = "openshift-origin-auth-mongo"
  s.version     = spec_file.match(/^Version:\s*(.*?)$/mi)[1].chomp
  s.authors     = ["Krishna Raman"]
  s.email       = ["kraman@gmail.com"]
  s.homepage    = 'https://github.com/openshift/origin-server'
  s.summary     = 'OpenShift Origin Mongo auth plugin'

  s.files       = Dir[lib_dir] + Dir[bin_dir] + Dir[conf_dir] + Dir[config_dir] + Dir[app_dir]
  s.test_files  = Dir[test_dir]
  s.executables = Dir[bin_dir].map {|binary| File.basename(binary)}
  s.files       += %w(README.md Rakefile Gemfile rubygem-openshift-origin-auth-mongo.spec openshift-origin-auth-mongo.gemspec LICENSE COPYRIGHT)
  s.require_paths = ["lib"]

  s.add_dependency('openshift-origin-controller')
  s.add_dependency('json')  
  s.add_development_dependency('rake', '>= 0.8.7', '<= 0.9.6')  
  s.add_development_dependency('bundler')
  s.add_development_dependency('mocha')
end
