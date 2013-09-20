namespace :test do

  Rake::TestTask.new :sanity => ['test:prepare'] do |t|
    t.libs << 'test'
    t.test_files = FileList[
      'test/unit/**/*_test.rb'
    ]
  end

  Rake::TestTask.new :functionals_ext => ['test:prepare'] do |t|
    t.libs << 'test'
    t.test_files = FileList[
      'test/functional_ext/rest_api_nolinks_test.rb'
    ]
  end

  Rake::TestTask.new :integration_ext => ['test:prepare'] do |t|
    t.libs << 'test'
    t.test_files = FileList[
      'test/integration_ext/*_test.rb'
    ]
  end

  Rake::TestTask.new :admin_console_functionals => ['test:prepare'] do |t|
    t.libs << 'test'
    t.test_files = FileList[
      '../admin-console/test/functional/**/*_test.rb'
    ]
  end

  Rake::TestTask.new :admin_console_integration => ['test:prepare'] do |t|
    t.libs << 'test'
    t.test_files = FileList[
      '../admin-console/test/integration/**/*_test.rb'
    ]
  end  
end
