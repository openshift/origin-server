# OS independent path locations
lib_dir  = File.join(File.join("lib", "**"), "*")
test_dir  = File.join(File.join("test", "**"), "*")
spec_file = "rubygem-stickshift-common.spec"

Gem::Specification.new do |s|
  s.name        = "stickshift-common"
  s.version     = `rpm -q --qf "%{version}\n" --specfile #{spec_file}`.split[0]
  s.license     = `rpm -q --qf "%{license}\n" --specfile #{spec_file}`.split[0]
  s.authors     = ["Krishna Raman"]
  s.email       = ["kraman@gmail.com"]
  s.homepage    = `rpm -q --qf "%{url}\n" --specfile #{spec_file}`.split[0]
  s.summary     = `rpm -q --qf "%{description}\n" --specfile #{spec_file}`.split[0]
  s.description = `rpm -q --qf "%{description}\n" --specfile #{spec_file}`.split[0]

  s.rubyforge_project = "stickshift-common"
  s.files       = Dir[lib_dir] + Dir[test_dir]
  s.files       += %w(README.md Rakefile Gemfile rubygem-stickshift-common.spec stickshift-common.gemspec LICENSE COPYRIGHT)
  s.require_paths = ["lib"]

  s.add_dependency("json")
  s.add_dependency("activemodel", "3.2.6")
  s.add_development_dependency('simplecov')
end
