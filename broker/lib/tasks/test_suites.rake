namespace :test do

  Rake::TestTask.new :sanity => ['test:prepare'] do |t|
    t.libs << 'test'
    t.test_files = FileList[
      'test/unit/cloud_user_test.rb',
      'test/unit/legacy_request_test.rb',
      'test/unit/mongo_data_store_test.rb',
      'test/functional/**/*_test.rb',
      'test/integration/**/*_test.rb'
    ]
  end

  Rake::TestTask.new :oo_unit1 => ['test:prepare'] do |t|
    t.libs << 'test'
    t.test_files = FileList[
      'test/unit/cloud_user_test.rb',
      'test/unit/legacy_request_test.rb',
      'test/unit/mongo_data_store_test.rb'
    ]
  end

  Rake::TestTask.new :oo_unit2 => ['test:prepare'] do |t|
    t.libs << 'test'
    t.test_files = FileList[
      'test/unit/rest_api_test.rb'
    ]
  end

  Rake::TestTask.new :oo_unit_ext1 => ['test:prepare'] do |t|
    t.libs << 'test'
    t.test_files = FileList[
      'test/unit/rest_api_nolinks_test.rb'
    ]
  end
end
