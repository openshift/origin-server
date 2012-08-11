# OS independent path locations
bin_dir  = File.join("bin", "*")
conf_dir = File.join("conf", "*")
lib_dir  = File.join(File.join("lib", "**"), "*")
misc_dir  = File.join(File.join("misc", "**"), "*")
test_dir  = File.join(File.join("test", "**"), "*")
spec_file = "stickshift-node.spec"

Gem::Specification.new do |s|
  s.name        = "stickshift-node"
  s.version     = `rpm -q --qf "%{version}\n" --specfile #{spec_file}`.split[0]
  s.license     = `rpm -q --qf "%{license}\n" --specfile #{spec_file}`.split[0]
  s.authors     = ["Krishna Raman"]
  s.email       = ["kraman@gmail.com"]
  s.homepage    = `rpm -q --qf "%{url}\n" --specfile #{spec_file}`.split[0]
  s.summary     = `rpm -q --qf "%{description}\n" --specfile #{spec_file}`.split[0]
  s.description = `rpm -q --qf "%{description}\n" --specfile #{spec_file}`.split[0]

  s.rubyforge_project = "stickshift-node"
  s.files       = Dir[lib_dir] + Dir[bin_dir] + Dir[conf_dir] + Dir[test_dir] + Dir[misc_dir]
  s.files       += %w(README.md Rakefile Gemfile stickshift-node.spec stickshift-node.gemspec COPYRIGHT LICENSE)
  s.executables = Dir[bin_dir].map {|binary| File.basename(binary)}
  s.require_paths = ["lib"]
  s.add_dependency("json")
  s.add_dependency("parseconfig")
  s.add_dependency("stickshift-common")

  s.add_development_dependency('rspec')
  s.add_development_dependency('mocha')
  s.add_development_dependency('rake')
  s.add_development_dependency('simplecov')
end
