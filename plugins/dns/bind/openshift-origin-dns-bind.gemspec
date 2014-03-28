# -*- encoding: utf-8 -*-
config_dir  = File.join(File.join("config", "**"), "*")
$:.push File.expand_path("../lib", __FILE__)
lib_dir  = File.join(File.join("lib", "**"), "*")
test_dir  = File.join(File.join("test", "**"), "*")
bin_dir  = File.join("bin", "*")
doc_dir  = File.join(File.join("doc", "**"), "*")
conf_dir  = File.join(File.join("conf", "**"), "*")
spec_file = "rubygem-openshift-origin-dns-bind.spec"

Gem::Specification.new do |s|
  spec_file = IO.read(File.expand_path("../rubygem-#{File.basename(__FILE__, '.gemspec')}.spec", __FILE__))

  s.name        = "openshift-origin-dns-bind"
  s.version     = spec_file.match(/^Version:\s*(.*?)$/mi)[1].chomp
  s.authors     = ["Krishna Raman"]
  s.email       = ["kraman@gmail.com"]
  s.homepage    = 'https://github.com/openshift/origin-server'
  s.summary     = 'OpenShift Origin DNS Bind plugin'

  s.files       = Dir[lib_dir] + Dir[doc_dir] + Dir[conf_dir] + Dir[config_dir]
  s.test_files  = Dir[test_dir]
  s.executables   = Dir[bin_dir]
  s.files       += %w(README.md Rakefile Gemfile rubygem-openshift-origin-dns-bind.spec openshift-origin-dns-bind.gemspec LICENSE COPYRIGHT)
  s.require_paths = ["lib"]

  s.add_dependency('openshift-origin-common')
  s.add_dependency('dnsruby')
  s.add_development_dependency('rake', '>= 0.8.7', '<= 0.9.6')  
  s.add_development_dependency('bundler')
end
