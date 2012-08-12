# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
lib_dir  = File.join(File.join("lib", "**"), "*")
test_dir  = File.join(File.join("test", "**"), "*")
bin_dir  = File.join("bin", "*")
spec_file = "stickshift-controller.spec"

Gem::Specification.new do |s|
  s.name        = "stickshift-controller"
  s.version     = `rpm -q --qf "%{version}\n" --specfile #{spec_file}`.split[0]
  s.license     = `rpm -q --qf "%{license}\n" --specfile #{spec_file}`.split[0]
  s.authors     = ["Krishna Raman"]
  s.email       = ["kraman@gmail.com"]
  s.homepage    = `rpm -q --qf "%{url}\n" --specfile #{spec_file}`.split[0]
  s.summary     = `rpm -q --qf "%{description}\n" --specfile #{spec_file}`.split[0]
  s.description = `rpm -q --qf "%{description}\n" --specfile #{spec_file}`.split[0]

  s.rubyforge_project = "stickshift-controller"

  s.files       = Dir[lib_dir]
  s.test_files  = Dir[test_dir]
  s.executables   = Dir[bin_dir]
  s.files       += %w(README.md Rakefile Gemfile stickshift-controller.spec stickshift-controller.gemspec LICENSE COPYRIGHT)
  s.require_paths = ["lib"]

  s.add_dependency "activesupport", "~> 3.0.13"
  s.add_dependency "json", "1.4.6"
  s.add_dependency "dnsruby"
  s.add_dependency "stickshift-common"
  s.add_dependency('state_machine')  
  s.add_dependency('open4')
  s.add_development_dependency('rake')  
  s.add_development_dependency('rspec')
  s.add_development_dependency('bundler')
  s.add_development_dependency('mocha')
  s.add_development_dependency('rcov')
  s.add_development_dependency('cucumber')
  s.add_development_dependency('dnsruby')
end
