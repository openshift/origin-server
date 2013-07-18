$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "admin_console/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openshift-origin-admin-console"
  s.version     = AdminConsole::VERSION
  s.authors     = ["Jessica Forrester"]
  s.email       = ["jforrest@redhat.com"]
  s.homepage    = 'https://github.com/openshift/origin-server/tree/master/admin-console'
  s.summary     = %q{OpenShift Origin Admin Console}
  s.description = %q{The OpenShift Origin admin console is a Rails engine that provides an easy-to-use interface for administering OpenShift Origin.}

  s.files = Dir["{app,conf,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.8"
  s.add_dependency 'formtastic',          '~> 1.2.4'
  s.add_dependency 'net-http-persistent', '>= 2.7'
  s.add_dependency 'haml',                '~> 3.1.7'
  s.add_dependency 'sass',        '~> 3.1.20' #required for haml
  s.add_dependency 'openshift-origin-common'
  s.add_dependency 'jquery-rails',        '~> 2.0.2'
end
