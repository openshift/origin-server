# -*- encoding: utf-8 -*-

app_dir  = File.join(File.join("app", "**"), "*")
config_dir  = File.join(File.join("config", "**"), "*")
$:.push File.expand_path("../lib", __FILE__)
lib_dir  = File.join(File.join("lib", "**"), "*")
test_dir  = File.join(File.join("test", "**"), "*")
bin_dir  = File.join("bin", "*")
spec_file = "rubygem-openshift-origin-controller.spec"

Gem::Specification.new do |s|
  spec_file = IO.read(File.expand_path("../rubygem-#{File.basename(__FILE__, '.gemspec')}.spec", __FILE__))

  s.name        = "openshift-origin-controller"
  s.version     = spec_file.match(/^Version:\s*(.*?)$/mi)[1].chomp
  s.authors     = ["Krishna Raman"]
  s.email       = ["kraman@gmail.com"]
  s.homepage    = 'https://github.com/openshift/origin-server'
  s.summary     = 'OpenShift Origin REST API and model'
  s.description = 'OpenShift Origin REST API and model'

  s.files       = Dir[lib_dir] + Dir[app_dir] + Dir[config_dir]
  s.test_files  = Dir[test_dir]
  s.executables   = Dir[bin_dir]
  s.files       += %w(README.md Rakefile Gemfile rubygem-openshift-origin-controller.spec openshift-origin-controller.gemspec LICENSE COPYRIGHT)
  s.require_paths = ["lib"]

  s.add_dependency "activesupport", "~> 3.2.8"
  s.add_dependency "openshift-origin-common"
  s.add_dependency('state_machine')
  s.add_dependency('dnsruby')
  s.add_dependency('net-ssh')
  s.add_dependency('httpclient')
  s.add_dependency 'mongoid', '>= 3.0.17'
  s.add_development_dependency('rake', '>= 0.8.7', '<= 0.9.6')  
  s.add_development_dependency('rspec')
  s.add_development_dependency('bundler')
  s.add_development_dependency('mocha')
  s.add_development_dependency('cucumber')
  s.add_development_dependency('dnsruby')
  s.add_development_dependency('open4')
  s.add_development_dependency("json", "1.4.6")
end
