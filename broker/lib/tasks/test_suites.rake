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
  
  Rake::TestTask.new :domain_system_test => ['test:prepare'] do |t|
    t.libs << 'test'
    t.test_files = FileList['test/system/domain_test.rb']
    t.verbose = true
  end

  Rake::TestTask.new :cartridge_system_test => ['test:prepare'] do |t|
    t.libs << "test"
    t.test_files = FileList['test/system/app_cartridge_events_test.rb', 'test/system/app_cartridges_test.rb']
    t.verbose = true
  end

  Rake::TestTask.new :application_system_test => ['test:prepare'] do |t|
    t.libs << "test"
    t.test_files = FileList['test/system/app_events_test.rb', 'test/system/application_test.rb', 'test/system/alias_test.rb', 'test/system/deployment_test.rb']
    t.verbose = true
  end

end
