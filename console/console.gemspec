$:.push File.expand_path("../lib", __FILE__)

require "console/version"

Gem::Specification.new do |s|
  s.name = 'console'
  s.version = Console::VERSION

  s.summary = %q{Openshift Application Console}
  s.description = %q{The OpenShift application console is a Rails engine that provides an easy-to-use interface for managing your OpenShift applications.}
  s.authors = ["Clayton Coleman"]
  s.email = ['smarterclayton@gmail.com']
  s.homepage = 'https://github.com/openshift/console'

  s.files = Dir['Gemfile', 'LICENSE.md', 'README.md', 'Rakefile', 'app/**/*', 'config/**/*', 'lib/**/*', 'public/**/*']
  s.test_files = Dir['test/**/*']

  #s.required_rubygems_version = s::Requirement.new('>= 1.3.6')
  s.add_dependency 'rails', '~> 3.0.13'

  # Console gem dependencies are explicitly specific since they must
  # match gems available in Fedora.  This may be relaxed at a future 
  # date.
  s.add_dependency 'formtastic', '~> 1.2.3'
  s.add_dependency 'net-http-persistent', '~> 2.3.2'
  s.add_dependency 'sass', '~> 3.1.7'
  s.add_dependency 'rack', '>= 1.2.5'
  s.add_dependency 'haml', '~> 3.1.2'
  s.add_dependency 'compass', '~> 0.11.5'
  s.add_dependency 'barista', '~> 1.2.1'
  s.add_dependency 'rdiscount', '~> 1.6.3'

  # Temporarily removed because of issues with Bundler < 1.0.22
  s.add_development_dependency 'mocha', '~> 0.9.8'
  s.add_development_dependency 'webmock', '~> 1.6.4'
  #s.add_dependency '', '~> '
end
