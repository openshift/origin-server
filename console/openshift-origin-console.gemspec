$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  spec_file = IO.read(File.expand_path("../rubygem-#{File.basename(__FILE__, '.gemspec')}.spec", __FILE__))

  s.name = 'openshift-origin-console'
  s.version = spec_file.match(/^Version:\s*(.*?)$/mi)[1].chomp 

  s.summary = %q{OpenShift Origin Management Console}
  s.description = %q{The OpenShift Origin console is a Rails engine that provides an easy-to-use interface for managing OpenShift Origin applications.}
  s.authors = ["Clayton Coleman", "Fabiano Franz", "Dan McPherson", "Matt Hicks", "Emily Dirsh", "Fotios Lindakos", 'J5']
  s.email = ['ccoleman@redhat.com', 'ffranz@redhat.com','dmcphers@redhat.com', 'mhicks@redhat.com', 'edirsh@redhat.com', 'fotios@redhat.com', 'johnp@redhat.com']
  s.homepage = 'https://github.com/openshift/crankcase/tree/master/console'

  s.files = Dir['Gemfile', 'LICENSE', 'COPYRIGHT', 'README.md', 'Rakefile', 'app/**/*', 'config/**/*', 'lib/**/*', 'public/**/*', 'vendor/**/*']
  s.test_files = Dir['test/**/*']

  # Console gem dependencies are explicitly specific since they must
  # match gems available in Fedora.  This may be relaxed at a future 
  # date.
  s.add_dependency 'rails',               '~> 3.2.8'
  s.add_dependency 'formtastic',          '~> 1.2.4'
  s.add_dependency 'net-http-persistent', '>= 2.7'
  s.add_dependency 'haml',                '~> 3.1.7'
  s.add_dependency 'rdiscount',           '~> 1.6.3'
end
