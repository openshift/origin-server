# OS independent path locations
conf_dir = File.join(File.join("conf", "**"), "*")
httpd_dir = File.join(File.join("httpd", "**"), "*")
lib_dir  = File.join(File.join("lib", "**"), "*")
misc_dir  = File.join(File.join("misc", "**"), "*")
jobs_dir  = File.join(File.join("jobs", "**"), "*")
test_dir  = File.join(File.join("test", "**"), "*")
spec_file = "rubygem-openshift-origin-node.spec"

Gem::Specification.new do |s|
  s.name        = "openshift-origin-node"
  s.version     = `rpm -q --define 'rhel 7' --qf "%{version}\n" --specfile #{spec_file}`.split[0]
  s.license     = `rpm -q --define 'rhel 7' --qf "%{license}\n" --specfile #{spec_file}`.split[0]
  s.authors     = ["Krishna Raman"]
  s.email       = ["kraman@gmail.com"]
  s.homepage    = `rpm -q --define 'rhel 7' --qf "%{url}\n" --specfile #{spec_file}`.split[0]
  s.summary     = `rpm -q --define 'rhel 7' --qf "%{description}\n" --specfile #{spec_file}`.split[0]
  s.description = `rpm -q --define 'rhel 7' --qf "%{description}\n" --specfile #{spec_file}`.split[0]

  s.rubyforge_project = "openshift-origin-node"
  s.files       = Dir[lib_dir] + Dir[conf_dir] + Dir[test_dir] + Dir[misc_dir] + Dir[httpd_dir] + Dir[jobs_dir]
  s.files       += %w(README.md Rakefile Gemfile rubygem-openshift-origin-node.spec openshift-origin-node.gemspec COPYRIGHT LICENSE)
  s.require_paths = ["lib"]
  s.add_dependency("json")
  s.add_dependency("parseconfig", ">= 0.5.2")
  s.add_dependency("openshift-origin-common")
  s.add_dependency("safe_yaml")
  s.add_dependency("parallel")

  s.add_development_dependency('rspec', "1.1.12")
  s.add_development_dependency('mocha', "0.9.8")
  s.add_development_dependency('rake', '>= 0.8.7', '<= 0.9.6')
end
