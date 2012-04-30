# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
lib_dir  = File.join(File.join("lib", "**"), "*")
test_dir  = File.join(File.join("test", "**"), "*")
bin_dir  = File.join("bin","*")

Gem::Specification.new do |s|
  s.name        = "swingshift-mongo-plugin"
  s.version     = /(Version: )(.*)/.match(File.read("swingshift-mongo-plugin.spec"))[2].strip
  s.license     = 'ASL 2.0'
  s.authors     = ["Krishna Raman"]
  s.email       = ["kraman@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Swingshift plugin for authenticating against a mongodb based user DB}
  s.description = %q{Provides a MongoDB based user database for authentication}

  s.rubyforge_project = "swingshift-mongo-plugin"

  s.files       = Dir[lib_dir] + Dir[bin_dir]
  s.test_files  = Dir[test_dir]
  s.executables = Dir[bin_dir].map {|binary| File.basename(binary)}
  s.files       += %w(README.md Rakefile Gemfile swingshift-mongo-plugin.spec swingshift-mongo-plugin.gemspec LICENSE COPYRIGHT)
  s.require_paths = ["lib"]

  s.add_dependency('stickshift-controller')
  s.add_dependency('json')  
  s.add_development_dependency('rake')  
  s.add_development_dependency('rspec')
  s.add_development_dependency('bundler')
  s.add_development_dependency('mocha')
end
