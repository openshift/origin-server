# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
lib_dir  = File.join(File.join("lib", "**"), "*")
test_dir  = File.join(File.join("spec", "**"), "*")
bin_dir  = File.join("bin", "*")
doc_dir  = File.join(File.join("doc", "**"), "*")
conf_dir  = File.join(File.join("conf", "**"), "*")
spec_file = "rubygem-openshift-origin-dns-dnsmasq.spec"

Gem::Specification.new do |s|
  s.name        = "openshift-origin-dns-dnsmasq"
  s.version     = `rpm -q --qf "%{version}\n" --specfile #{spec_file}`.split[0]
  s.license     = `rpm -q --qf "%{license}\n" --specfile #{spec_file}`.split[0]
  s.authors     = ["Mark Lamourine"]
  s.email       = ["markllama@gmail.com"]
  s.homepage    = `rpm -q --qf "%{url}\n" --specfile #{spec_file}`.split[0]
  s.summary     = `rpm -q --qf "%{description}\n" --specfile #{spec_file}`.split[0]
  s.description = `rpm -q --qf "%{description}\n" --specfile #{spec_file}`.split[0]

  s.rubyforge_project = "openshift-origin-dns-dnsmasq"

  s.files       = Dir[lib_dir] + Dir[doc_dir] + Dir[conf_dir]
  s.test_files  = Dir[test_dir]
  s.executables   = Dir[bin_dir]
  s.files       += %w(README.md Rakefile Gemfile rubygem-openshift-origin-dns-dnsmasq.spec openshift-origin-dns-dnsmasq.gemspec LICENSE COPYRIGHT)
  s.require_paths = ["lib"]

  s.add_dependency('openshift-origin-controller')

  s.add_development_dependency('rake')  
  s.add_development_dependency('rspec')
  s.add_development_dependency('bundler')
  s.add_development_dependency('mocha')
  s.add_development_dependency('rdoc')
end
