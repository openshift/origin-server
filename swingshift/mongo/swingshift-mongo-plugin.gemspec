$:.push File.expand_path("../lib", __FILE__)
bin_dir  = File.join("bin","*")
spec_file = "swingshift-mongo-plugin.spec"

# Maintain your gem's version:
require "swingshift-mongo-plugin/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "swingshift-mongo-plugin"
  s.version     = SwingShift::VERSION
  s.authors     = ["Krishna Raman"]
  s.email       = ["kraman@gmail.com"]
  s.homepage    = "http://www.openshift.com"
  s.summary     = %q{Swingshift plugin for authenticating against a mongodb based user DB}
  s.description = %q{Provides a MongoDB based user database for authentication}

  s.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE", "COPYRIGHT", "Rakefile", "README.md", "swingshift-mongo-plugin.gemspec", "swingshift-mongo-plugin.spec", "Gemfile"]
  s.test_files = Dir["test/**/*"]
  s.executables = Dir[bin_dir].map {|binary| File.basename(binary)}

  s.add_dependency "rails", "~> 3.2.6"
  s.add_dependency "stickshift-controller"
  s.add_dependency "stickshift-common"
  s.add_dependency "mongoid"  
end
