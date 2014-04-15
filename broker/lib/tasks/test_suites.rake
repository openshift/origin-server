namespace :test do

  desc "Sanity tests"
  Rake::TestTask.new :sanity => ['test:prepare'] do |t|
    t.libs << 'test'
    t.test_files = FileList[
      'test/unit/**/*_test.rb'
    ]
  end

  functionals = []

  desc "Functional tests 1"
  Rake::TestTask.new :functionals1 => ['test:prepare'] do |t|
    t.verbose = true
    t.libs << 'test'
    tests = FileList[
      'test/functional/access_controlled_test.rb',
      'test/functional/admin_stats_db_test.rb',
      'test/functional/alias_controller_test.rb',
      'test/functional/alias_test.rb',
      'test/functional/api_controller_test.rb',
      'test/functional/app_events_controller_test.rb',
      'test/functional/application_controller_test.rb',
      'test/functional/authorizations_controller_test.rb',
      'test/functional/cartridges_controller_test.rb',
      'test/functional/cartridge_type_test.rb',
      'test/functional/cloud_user_test.rb',
      'test/functional/deployments_controller_test.rb',
      'test/functional/deployment_test.rb',
      'test/functional/descriptors_controller_test.rb',
      'test/functional/user_controller_test.rb',
      'test/functional/distributed_lock_test.rb'
    ]
    functionals += tests
    t.test_files = tests
  end

  desc "Functional tests 2"
  Rake::TestTask.new :functionals2 => ['test:prepare'] do |t|
    t.verbose = true
    t.libs << 'test'
    tests = FileList[
      'test/functional/application_test.rb',
      'test/functional/district_test.rb',
      'test/functional/dns_resolvable_controller_test.rb',
      'test/functional/domains_controller_test.rb',
      'test/functional/domain_test.rb',
      'test/functional/emb_cart_controller_test.rb',
      'test/functional/emb_cart_events_controller_test.rb',
      'test/functional/environment_controller_test.rb',
      'test/functional/environment_variables_controller_test.rb',
      'test/functional/gear_groups_controller_test.rb',
      'test/functional/keys_controller_test.rb',
      'test/functional/lock_test.rb',
      'test/functional/name_server_cache_test.rb',
      'test/functional/node_selection_test.rb',
      'test/functional/quickstarts_controller_test.rb',
      'test/functional/region_test.rb'
    ]
    functionals += tests
    t.test_files = tests
  end

  desc "Functional tests 3"
  Rake::TestTask.new :functionals3 => ['test:prepare'] do |t|
    t.verbose = true
    t.libs << 'test'
    oo_functionals = Dir.glob('test/functional/oo_*_test.rb')
    all_functionals = Dir.glob('test/functional/*_test.rb')
    t.test_files = (all_functionals - functionals) - oo_functionals
  end

  ext_functionals = []

  desc "Extended Functional tests 1"
  Rake::TestTask.new :functionals_ext1 => ['test:prepare'] do |t|
    t.verbose = true
    t.libs << 'test'
    tests = FileList[
      'test/functional_ext/alias_test.rb'
    ]
    ext_functionals += tests
    t.test_files = tests
  end

  desc "Extended Functional tests 2"
  Rake::TestTask.new :functionals_ext2 => ['test:prepare'] do |t|
    t.verbose = true
    t.libs << 'test'
    tests = FileList[
      'test/functional_ext/app_cartridge_events_test.rb',
      'test/functional_ext/app_cartridges_test.rb',
      'test/functional_ext/app_events_test.rb',
      'test/functional_ext/application_test.rb'
    ]
    ext_functionals += tests
    t.test_files = tests
  end

  desc "Extended Functional tests 3"
  Rake::TestTask.new :functionals_ext3 => ['test:prepare'] do |t|
    t.verbose = true
    t.libs << 'test'
    tests = FileList[
      'test/functional_ext/deployment_test.rb',
      'test/functional_ext/domain_test.rb',
      'test/functional_ext/rest_api_nolinks_test.rb'
    ]
    ext_functionals += tests
    t.test_files = tests
  end

  desc "Extended Functional tests 4"
  Rake::TestTask.new :functionals_ext4 => ['test:prepare'] do |t|
    t.verbose = true
    t.libs << 'test'
    all_ext_functionals = Dir.glob('test/functional_ext/*_test.rb')
    oo_functionals = Dir.glob('test/functional_ext/oo_*_test.rb')
    t.test_files = (all_ext_functionals - ext_functionals) - oo_functionals
  end

  desc "Extended Integration tests"
  Rake::TestTask.new :integration_ext => ['test:prepare'] do |t|
    t.verbose = true
    t.libs << 'test'
    t.test_files = FileList[
      'test/integration_ext/*_test.rb'
    ]
  end

  desc "Admin Console Functional tests"
  Rake::TestTask.new :admin_console_functionals => ['test:prepare'] do |t|
    t.verbose = true
    t.libs << 'test'
    t.test_files = FileList[
      '../admin-console/test/functional/**/*_test.rb'
    ]
  end

  desc "Admin Console Integration tests"
  Rake::TestTask.new :admin_console_integration => ['test:prepare'] do |t|
    t.verbose = true
    t.libs << 'test'
    t.test_files = FileList[
      '../admin-console/test/integration/**/*_test.rb'
    ]
  end  

  desc "OO Admin Script tests"
  Rake::TestTask.new :oo_admin_scripts => ['test:prepare'] do |t|
    t.verbose = true
    t.libs << "test"
    t.test_files = FileList[
      'test/functional/oo_*_test.rb',
      'test/functional_ext/oo_*_test.rb'
    ]
  end

  desc "Membership tests"
  Rake::TestTask.new :membership => ['test:prepare'] do |t|
    t.verbose = true
    t.libs << "test"
    t.test_files = FileList[
      'test/unit/member_test.rb',
      'test/unit/team_test.rb',
      'test/functional/access_controlled_test.rb',
      'test/functional/domain_members_controller_test.rb',
      'test/functional/team_members_controller_test.rb',
      'test/functional/teams_controller_test.rb'
    ]
  end

end
