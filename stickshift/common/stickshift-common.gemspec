# OS independent path locations
lib_dir  = File.join(File.join("lib", "**"), "*")
test_dir  = File.join(File.join("test", "**"), "*")

Gem::Specification.new do |s|
  s.name        = "stickshift-common"
  s.version     = /(Version: )(.*)/.match(File.read("stickshift-common.spec"))[2].strip
  s.license     = 'ASL 2.0'
  s.authors     = ["Krishna Raman"]
  s.email       = ["kraman@gmail.com"]
  s.homepage    = "http://www.openshift.com"
  s.summary     = %q{Cloud Development Common}
  s.description = %q{Cloud Development Common}

  s.rubyforge_project = "stickshift-common"
  s.files       = Dir[lib_dir] + Dir[test_dir]
  s.files       += %w(README.md Rakefile Gemfile stickshift-common.spec stickshift-common.gemspec LICENSE COPYRIGHT)
  s.require_paths = ["lib"]

  s.add_dependency("json")
  s.add_dependency("activemodel")
  s.add_dependency("mongo")
end
