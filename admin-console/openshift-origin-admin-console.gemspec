$:.push File.expand_path("../lib", __FILE__)

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|

  s.name        = "openshift-origin-admin-console"
  spec_file = IO.read("rubygem-#{s.name}.spec")
  s.version = spec_file.match(/^Version:\s*(.*?)$/mi)[1].chomp
  s.authors     = ["Jessica Forrester", "Luke Meyer", "Steve Goodwin"]
  s.email       = ["jforrest@redhat.com", "lmeyer@redhat.com", "sgoodwin@redhat.com"]
  s.homepage    = 'https://github.com/openshift/origin-server/tree/master/admin-console'
  s.summary     = %q{OpenShift Origin Admin Console}
  s.description = %q{The OpenShift Origin admin console is a Rails engine that provides an easy-to-use interface for administering OpenShift Origin.}

  s.files = Dir["{app,conf,config,db,lib}/**/*"] + ["LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails",                  '~> 3.2.8'
  s.add_dependency 'formtastic',             '~> 1.2.3'
  s.add_dependency 'jquery-rails',           '~> 3.1.0'
  s.add_dependency 'compass-rails',          '~> 1.0.3'
  s.add_dependency 'coffee-rails',           '~> 3.2.2'
  s.add_dependency 'sass-rails',             '~> 3.2.5'
  s.add_dependency 'haml',                   '>= 3.1.7', '< 4.1'
  s.add_dependency 'uglifier',               '>= 1.2.6'
  s.add_dependency 'therubyracer',           '>= 0.10'
  s.add_dependency 'net-http-persistent',    '>= 2.7'
  s.add_dependency 'sass-twitter-bootstrap', '~> 2.0.1'
  s.add_dependency 'openshift-origin-common'
  s.add_dependency 'openshift-origin-controller'
end
