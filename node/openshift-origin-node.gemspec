# OS independent path locations
bin_dir  = File.join("bin", "*")
conf_dir = File.join("conf", "*")
lib_dir  = File.join(File.join("lib", "**"), "*")
misc_dir  = File.join(File.join("misc", "**"), "*")
test_dir  = File.join(File.join("test", "**"), "*")
spec_file = "rubygem-openshift-origin-node.spec"

Gem::Specification.new do |s|
  s.name        = "openshift-origin-node"
  s.version     = `rpmspec -q --qf "%{version}\n" #{spec_file}`.split[0]
  s.license     = `rpmspec -q --qf "%{license}\n" #{spec_file}`.split[0]
  s.authors     = ["Krishna Raman"]
  s.email       = ["kraman@gmail.com"]
  s.homepage    = `rpmspec -q --qf "%{url}\n" #{spec_file}`.split[0]
  s.summary     = `rpmspec -q --qf "%{description}\n" #{spec_file}`.split[0]
  s.description = `rpmspec -q --qf "%{description}\n" #{spec_file}`.split[0]

  s.rubyforge_project = "openshift-origin-node"
  s.files       = Dir[lib_dir] + Dir[bin_dir] + Dir[conf_dir] + Dir[test_dir] + Dir[misc_dir]
  s.files       += %w(README.md Rakefile Gemfile rubygem-openshift-origin-node.spec openshift-origin-node.gemspec COPYRIGHT LICENSE)
  s.executables = Dir[bin_dir].map {|binary| File.basename(binary)}
  s.require_paths = ["lib"]
  s.add_dependency("json")
  s.add_dependency("parseconfig", ">= 0.5.2")
  s.add_dependency("openshift-origin-common")

  s.add_development_dependency('rspec')
  s.add_development_dependency('mocha', "0.9.8")
  s.add_development_dependency('rake', '>= 0.8.7', '<= 0.9.2.2')
end
