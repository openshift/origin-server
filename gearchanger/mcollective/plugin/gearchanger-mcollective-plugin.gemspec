# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
lib_dir  = File.join(File.join("lib", "**"), "*")
test_dir  = File.join(File.join("test", "**"), "*")
docs_dir  = File.join(File.join("docs", "**"), "*")
spec_file = "gearchanger-mcollective-plugin.spec"

Gem::Specification.new do |s|
  s.name        = "gearchanger-mcollective-plugin"
  s.version     = `rpm -q --qf "%{version}\n" --specfile #{spec_file}`.split[0]
  s.license     = `rpm -q --qf "%{license}\n" --specfile #{spec_file}`.split[0]
  s.authors     = ["Krishna Raman"]
  s.email       = ["kraman@gmail.com"]
  s.homepage    = `rpm -q --qf "%{url}\n" --specfile #{spec_file}`.split[0]
  s.summary     = `rpm -q --qf "%{description}\n" --specfile #{spec_file}`.split[0]
  s.description = `rpm -q --qf "%{description}\n" --specfile #{spec_file}`.split[0]

  s.rubyforge_project = "gearchanger-mcollective-plugin"

  s.files       = Dir[lib_dir] + Dir[docs_dir]
  s.test_files  = Dir[test_dir]
  s.files       += %w(README.md Rakefile Gemfile gearchanger-mcollective-plugin.spec gearchanger-mcollective-plugin.gemspec LICENSE COPYRIGHT)
  s.require_paths = ["lib"]

  s.add_dependency('stickshift-controller')
  s.add_dependency('json')  
  s.add_dependency('systemu')  
  s.add_development_dependency('rake')  
  s.add_development_dependency('rspec')
  s.add_development_dependency('bundler')
  s.add_development_dependency('mocha')

  #required because mcollective had a dependency
  s.add_dependency('stomp')
end
