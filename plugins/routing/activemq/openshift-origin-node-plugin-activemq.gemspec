# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
lib_dir  = File.join(File.join("lib", "**"), "*")
docs_dir  = File.join(File.join("docs", "**"), "*")
spec_file = "rubygem-openshift-origin-node-plugin-activemq.spec"

Gem::Specification.new do |s|
  s.name        = "openshift-origin-node-plugin-activemq"
  s.version     = `rpm -q --define 'rhel 7' --qf "%{version}\n" --specfile #{spec_file}`.split[0]
  s.license     = `rpm -q --define 'rhel 7' --qf "%{license}\n" --specfile #{spec_file}`.split[0]
  s.authors     = ["Miciah Dashiel Butler Masters"]
  s.email       = ["mmasters@redhat.com"]
  s.homepage    = `rpm -q --define 'rhel 7' --qf "%{url}\n" --specfile #{spec_file}`.split[0]
  s.summary     = `rpm -q --define 'rhel 7' --qf "%{description}\n" --specfile #{spec_file}`.split[0]
  s.description = `rpm -q --define 'rhel 7' --qf "%{description}\n" --specfile #{spec_file}`.split[0]

  s.files       = Dir[lib_dir] + Dir[docs_dir]
  s.files       += %w(README.md Rakefile Gemfile rubygem-openshift-origin-node-plugin-activemq.spec openshift-origin-node-plugin-activemq.gemspec LICENSE COPYRIGHT)
  s.require_paths = ["lib"]

  s.add_dependency('openshift-origin-node')
  s.add_dependency('stomp')  
  s.add_development_dependency('rake', '>= 0.8.7', '<= 0.9.6')  
  s.add_development_dependency('rspec')
  s.add_development_dependency('bundler')
  s.add_development_dependency('mocha')
end
