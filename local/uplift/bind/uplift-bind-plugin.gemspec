# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
lib_dir  = File.join(File.join("lib", "**"), "*")
test_dir  = File.join(File.join("test", "**"), "*")
bin_dir  = File.join("bin", "*")
doc_dir  = File.join(File.join("doc", "**"), "*")

Gem::Specification.new do |s|
  s.name        = "uplift-bind-plugin"
  s.version     = /(Version: )(.*)/.match(File.read("uplift-bind-plugin.spec"))[2].strip
  s.license     = 'ASL 2.0'
  s.authors     = ["Krishna Raman"]
  s.email       = ["kraman@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Uplift plugin for configuring BIND DNS daemon}
  s.description = %q{Provides a BIND based plugin}

  s.rubyforge_project = "uplift-bind-plugin"

  s.files       = Dir[lib_dir] + Dir[doc_dir]
  s.test_files  = Dir[test_dir]
  s.executables   = Dir[bin_dir]
  s.files       += %w(README.md Rakefile Gemfile uplift-bind-plugin.spec uplift-bind-plugin.gemspec LICENSE COPYRIGHT)
  s.require_paths = ["lib"]

  s.add_dependency('stickshift-controller')
  s.add_dependency('json')  
  s.add_development_dependency('rake')  
  s.add_development_dependency('rspec')
  s.add_development_dependency('bundler')
  s.add_development_dependency('mocha')
end
