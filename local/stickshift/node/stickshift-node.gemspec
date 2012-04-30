# OS independent path locations
bin_dir  = File.join("bin", "*")
conf_dir = File.join("conf", "*")
lib_dir  = File.join(File.join("lib", "**"), "*")
misc_dir  = File.join(File.join("misc", "**"), "*")
test_dir  = File.join(File.join("test", "**"), "*")

Gem::Specification.new do |s|
  s.name        = "stickshift-node"
  s.version     = /(Version: )(.*)/.match(File.read("stickshift-node.spec"))[2].strip
  s.license     = 'ASL 2.0'
  s.authors     = ["Krishna Raman"]
  s.email       = ["kraman@gmail.com"]
  s.homepage    = "http://www.openshift.com"
  s.summary     = %q{Cloud Development Node}
  s.description = %q{Cloud Development Node}

  s.rubyforge_project = "stickshift-node"
  s.files       = Dir[lib_dir] + Dir[bin_dir] + Dir[conf_dir] + Dir[test_dir] + Dir[misc_dir]
  s.files       += %w(README.md Rakefile Gemfile stickshift-node.spec stickshift-node.gemspec COPYRIGHT LICENSE)
  s.executables = Dir[bin_dir].map {|binary| File.basename(binary)}
  s.require_paths = ["lib"]
  s.add_dependency("json")
  s.add_dependency("parseconfig")
  s.add_dependency("stickshift-common")

  s.add_development_dependency('rspec')
  s.add_development_dependency('mocha', "0.9.8")
  s.add_development_dependency('rake', ">= 0.8.7")
end
