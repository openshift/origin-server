$:.push File.expand_path("../lib", __FILE__)

require "console/version"

Gem::Specification.new do |s|
  s.name = 'openshift-origin-console'
  s.version = Console::VERSION::STRING

  s.summary = %q{Openshift Origin Management Console}
  s.description = %q{The OpenShift Origin console is a Rails engine that provides an easy-to-use interface for managing OpenShift Origin applications.}
  s.authors = ["Clayton Coleman", "Fabiano Franz", "Dan McPherson", "Matt Hicks", "Emily Dirsh", "Fotios Lindakos", 'J5']
  s.email = ['ccoleman@redhat.com', 'ffranz@redhat.com','dmcphers@redhat.com', 'mhicks@redhat.com', 'edirsh@redhat.com', 'fotios@redhat.com', 'johnp@redhat.com']
  s.homepage = 'https://github.com/openshift/crankcase/tree/master/console'

  s.files = Dir['Gemfile', 'LICENSE', 'COPYRIGHT', 'README.md', 'Rakefile', 'app/**/*', 'config/**/*', 'lib/**/*', 'public/**/*']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'rails', '~> 3.2.8'

  # Console gem dependencies are explicitly specific since they must
  # match gems available in Fedora.  This may be relaxed at a future 
  # date.
  s.add_dependency 'formtastic', '~> 1.2.3'
  s.add_dependency 'net-http-persistent', '~> 2.3.2'
#  s.add_dependency 'sass', '~> 3.1.7'
#  s.add_dependency 'rack', '>= 1.2.5'
  s.add_dependency 'haml', '~> 3.1.2'
#  s.add_dependency 'compass', '~> 0.11.5'
#  s.add_dependency 'barista', '~> 1.2.1'
  s.add_dependency 'rdiscount', '~> 1.6.3'

  #s.add_dependency '', '~> '
end
