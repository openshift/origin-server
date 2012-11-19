# -*- encoding: utf-8 -*-
config_dir  = File.join(File.join("config", "**"), "*")
$:.push File.expand_path("../lib", __FILE__)
lib_dir  = File.join(File.join("lib", "**"), "*")
test_dir  = File.join(File.join("test", "**"), "*")
docs_dir  = File.join(File.join("docs", "**"), "*")
conf_dir  = File.join(File.join("conf", "**"), "*")
spec_file = "rubygem-openshift-origin-msg-broker-mcollective.spec"

Gem::Specification.new do |s|
  s.name        = "openshift-origin-msg-broker-mcollective"
  s.version     = `rpmspec -q --qf "%{version}\n" #{spec_file}`.split[0]
  s.license     = `rpmspec -q --qf "%{license}\n" #{spec_file}`.split[0]
  s.authors     = ["Krishna Raman"]
  s.email       = ["kraman@gmail.com"]
  s.homepage    = `rpmspec -q --qf "%{url}\n" #{spec_file}`.split[0]
  s.summary     = `rpmspec -q --qf "%{description}\n" #{spec_file}`.split[0]
  s.description = `rpmspec -q --qf "%{description}\n" #{spec_file}`.split[0]

  s.rubyforge_project = "msg-broker-mcollective-plugin"

  s.files       = Dir[lib_dir] + Dir[docs_dir] + Dir[conf_dir] + Dir[config_dir]
  s.test_files  = Dir[test_dir]
  s.files       += %w(README.md Rakefile Gemfile rubygem-openshift-origin-msg-broker-mcollective.spec openshift-origin-msg-broker-mcollective.gemspec LICENSE COPYRIGHT)
  s.require_paths = ["lib"]

  s.add_dependency('openshift-origin-controller')
  s.add_dependency('json')  
  s.add_dependency('systemu')  
  s.add_development_dependency('rake', '>= 0.8.7', '<= 0.9.2.2')  
  s.add_development_dependency('rspec')
  s.add_development_dependency('bundler')
  s.add_development_dependency('mocha')

  #required because mcollective had a dependency
  s.add_dependency('stomp')
end
