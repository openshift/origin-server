# OS independent path locations
lib_dir  = File.join(File.join("lib", "**"), "*")
test_dir  = File.join(File.join("test", "**"), "*")
spec_file = "rubygem-openshift-origin-common.spec"

Gem::Specification.new do |s|
  s.name        = "openshift-origin-common"
  s.version     = `rpmspec -q --qf "%{version}\n" #{spec_file}`.split[0]
  s.license     = `rpmspec -q --qf "%{license}\n" #{spec_file}`.split[0]
  s.authors     = ["Krishna Raman"]
  s.email       = ["kraman@gmail.com"]
  s.homepage    = `rpmspec -q --qf "%{url}\n" #{spec_file}`.split[0]
  s.summary     = `rpmspec -q --qf "%{description}\n" #{spec_file}`.split[0]
  s.description = `rpmspec -q --qf "%{description}\n" #{spec_file}`.split[0]

  s.rubyforge_project = "openshift-origin-common"
  s.files       = Dir[lib_dir] + Dir[test_dir]
  s.files       += %w(README.md Rakefile Gemfile rubygem-openshift-origin-common.spec openshift-origin-common.gemspec LICENSE COPYRIGHT)
  s.require_paths = ["lib"]

  s.add_development_dependency('rake')

  s.add_dependency("json")
  s.add_dependency("activemodel")
end
