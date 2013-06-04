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
end
