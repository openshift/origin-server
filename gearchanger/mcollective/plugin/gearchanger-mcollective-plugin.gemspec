# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
lib_dir  = File.join(File.join("lib", "**"), "*")
test_dir  = File.join(File.join("test", "**"), "*")
docs_dir  = File.join(File.join("docs", "**"), "*")

Gem::Specification.new do |s|
  s.name        = "gearchanger-mcollective-plugin"
  s.version     = /(Version: )(.*)/.match(File.read("gearchanger-mcollective-plugin.spec"))[2].strip
  s.license     = 'ASL 2.0'
  s.authors     = ["Krishna Raman"]
  s.email       = ["kraman@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Gearchanger plugin for managing nodes/gears over mcollective}
  s.description = %q{Provides a mcollective based plugin to manage nodes/gears}

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
