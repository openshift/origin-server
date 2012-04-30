# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
lib_dir  = File.join(File.join("lib", "**"), "*")
test_dir  = File.join(File.join("test", "**"), "*")
bin_dir  = File.join("bin", "*")

Gem::Specification.new do |s|
  s.name        = "stickshift-controller"
  s.version     = /(Version: )(.*)/.match(File.read("stickshift-controller.spec"))[2].strip
  s.license     = 'ASL 2.0'
  s.authors     = ["Krishna Raman"]
  s.email       = ["kraman@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{StickShift Controller Rails Engine}
  s.description = %q{StickShift Controller Rails Engine}

  s.rubyforge_project = "stickshift-controller"

  s.files       = Dir[lib_dir]
  s.test_files  = Dir[test_dir]
  s.executables   = Dir[bin_dir]
  s.files       += %w(README.md Rakefile Gemfile stickshift-controller.spec stickshift-controller.gemspec LICENSE COPYRIGHT)
  s.require_paths = ["lib"]

  s.add_dependency "activesupport", "~> 3.0.10"
  s.add_dependency "json", "1.4.6"
  s.add_dependency "dnsruby"
  s.add_dependency "stickshift-common"
  s.add_dependency('state_machine')  
  s.add_dependency('open4')
  s.add_development_dependency('rake')  
  s.add_development_dependency('rspec')
  s.add_development_dependency('bundler')
  s.add_development_dependency('mocha')
  s.add_development_dependency('cucumber')
end
