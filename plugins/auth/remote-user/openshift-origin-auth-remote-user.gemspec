# -*- encoding: utf-8 -*-
config_dir  = File.join(File.join("config", "**"), "*")
$:.push File.expand_path("../lib", __FILE__)
lib_dir  = File.join(File.join("lib", "**"), "*")
test_dir  = File.join(File.join("test", "**"), "*")
bin_dir  = File.join("bin","*")
conf_dir  = File.join(File.join("conf", "**"), "*")
spec_file = "rubygem-openshift-origin-auth-remote-user.spec"

Gem::Specification.new do |s|
  s.name        = "openshift-origin-auth-remote-user"
  s.version     = `rpmspec -q --qf "%{version}\n" #{spec_file}`.split[0]
  s.license     = `rpmspec -q --qf "%{license}\n" #{spec_file}`.split[0]
  s.authors     = ["Brenton Leanhardt"]
  s.email       = ["bleanhar@redhat.com"]
  s.homepage    = `rpmspec -q --qf "%{url}\n" #{spec_file}`.split[0]
  s.summary     = `rpmspec -q --qf "%{description}\n" #{spec_file}`.split[0]
  s.description = `rpmspec -q --qf "%{description}\n" #{spec_file}`.split[0]

  s.rubyforge_project = "openshift-origin-auth-remote-user"

  s.files       = Dir[lib_dir] + Dir[bin_dir] + Dir[conf_dir] + Dir[config_dir]
  s.test_files  = Dir[test_dir]
  s.executables = Dir[bin_dir].map {|binary| File.basename(binary)}
  s.files       += %w(README.md Rakefile Gemfile rubygem-openshift-origin-auth-remote-user.spec openshift-origin-auth-remote-user.gemspec LICENSE COPYRIGHT README-LDAP README-KERB)
  s.require_paths = ["lib"]

  s.add_dependency('openshift-origin-controller')
  s.add_dependency('json')
  s.add_development_dependency('rake', '>= 0.8.7', '<= 0.9.2.2')
  s.add_development_dependency('bundler')
  s.add_development_dependency('mocha')
end
