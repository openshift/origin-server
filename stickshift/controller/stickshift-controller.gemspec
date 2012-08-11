$:.push File.expand_path("../lib", __FILE__)
bin_dir  = File.join("bin","*")

# Maintain your gem's version:
require "stickshift-controller/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "stickshift-controller"
  s.version     = StickShift::VERSION
  s.license     = 'ASL 2.0'
  s.authors     = ["Krishna Raman"]
  s.email       = ["kraman@gmail.com"]
  s.homepage    = "http://www.openshift.com"
  s.summary     = %q{StickShift Controller Rails Engine}
  s.description = %q{StickShift Controller Rails Engine}

  s.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE", "Rakefile", "README.md", "COPYRIGHT", "stickshift-controller.spec","Gemfile"]
  s.test_files = Dir["test/**/*"]
  s.executables = Dir[bin_dir].map {|binary| File.basename(binary)}

  s.add_dependency "rails", "= 3.2.6"

  s.add_dependency "json"
  s.add_dependency "dnsruby"
  s.add_dependency "stickshift-common"
  s.add_dependency "state_machine" 
  s.add_dependency "open4"
  s.add_dependency "mongoid"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "bundler"
  s.add_development_dependency "mocha"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "cucumber"
  s.add_development_dependency "dnsruby"
  s.add_development_dependency "minitest"
  s.add_development_dependency "sqlite3"
end
