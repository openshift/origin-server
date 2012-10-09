# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
lib_dir  = File.join(File.join("lib", "**"), "*")
test_dir  = File.join(File.join("test", "**"), "*")
bin_dir  = File.join("bin","*")
spec_file = "rubygem-openshift-origin-auth-remote-user.spec"

Gem::Specification.new do |s|
  s.name        = "openshift-origin-auth-remote-user"
  s.version     = `rpm -q --qf "%{version}\n" --specfile #{spec_file}`.split[0]
  s.license     = `rpm -q --qf "%{license}\n" --specfile #{spec_file}`.split[0]
  s.authors     = ["Brenton Leanhardt"]
  s.email       = ["bleanhar@redhat.com"]
  s.homepage    = `rpm -q --qf "%{url}\n" --specfile #{spec_file}`.split[0]
  s.summary     = `rpm -q --qf "%{description}\n" --specfile #{spec_file}`.split[0]
  s.description = `rpm -q --qf "%{description}\n" --specfile #{spec_file}`.split[0]

  s.rubyforge_project = "openshift-origin-auth-remote-user"

  s.files       = Dir[lib_dir] + Dir[bin_dir]
  s.test_files  = Dir[test_dir]
  s.executables = Dir[bin_dir].map {|binary| File.basename(binary)}
  s.files       += %w(README.md Rakefile Gemfile rubygem-openshift-origin-auth-remote-user.spec openshift-origin-auth-remote-user.gemspec LICENSE COPYRIGHT README-LDAP README-KERB)
  s.require_paths = ["lib"]

  s.add_dependency('openshift-origin-controller')
  s.add_dependency('json')
  s.add_development_dependency('rake')
  s.add_development_dependency('bundler')
  s.add_development_dependency('mocha')
end
