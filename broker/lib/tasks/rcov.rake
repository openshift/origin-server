#
# Configure rcov analysis of tests
# Derived from http://www.betaful.com/2010/11/rails-3-rcov-test-coverage/
#

namespace :rcov do
 
  task :clean do
    rm_rf "test/coverage"
    rm_rf "test/coverage.data"
    Rcov = "cd test && rcov --rails --aggregate coverage.data -Ilib \
                        --text-summary -x '/usr/lib/ruby' \
                        -i 'openshift,rhc'"
  end

  desc 'Coverage analysis of unit tests'
  task :units => :clean do
    system("#{Rcov} --html unit/*_test.rb")
  end
 
  desc 'Coverage analysis of functional tests'
  task :functionals => :clean do
    system("#{Rcov} --html functional/*_test.rb")
  end
 
  desc 'Coverage analysis of integration tests'
  task :integration => :clean do
    system("#{Rcov} --html integration/*_test.rb")
  end

  desc 'Coverage analysis of all tests'
  task :all => :clean do
    Rake::Task["rcov:units"].invoke
    Rake::Task["rcov:functionals"].invoke
    Rake::Task["rcov:integration"].invoke
  end
 
end
 
task :rcov do
  Rake::Task["rcov:all"].invoke
end
