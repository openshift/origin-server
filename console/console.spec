# encoding: utf-8
require File.expand_path('../lib/console/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors = ["Clayton Coleman"]
  gem.description = %q{The OpenShift application console is a Rails engine that provides an easy-to-use interface for managing your OpenShift applications.}
  gem.email = ['smarterclayton@gmail.com']
  gem.files = Dir['Gemfile', 'LICENSE.md', 'README.md', 'Rakefile', 'app/**/*', 'config/**/*', 'lib/**/*', 'public/**/*']
  gem.homepage = 'https://github.com/openshift/console'
  gem.name = 'console'
  gem.require_paths = ['lib']
  #gem.required_rubygems_version = Gem::Requirement.new('>= 1.3.6')
  gem.summary = %q{Openshift Application Console}
  gem.test_files = Dir['test/**/*']
  gem.version = Console::VERSION
end
