namespace :test do

  Rake::TestTask.new :sanity => ['test:prepare'] do |t|
    t.libs << 'test'
    t.test_files = FileList[
      'test/unit/**/*_test.rb'
    ]
  end

  Rake::TestTask.new :functionals1 => ['test:prepare'] do |t|
    t.libs << 'test'
    t.test_files = FileList[
      'test/functional/access_controlled_test.rb',
      'test/functional/admin_stats_db_test.rb',
      'test/functional/alias_controller_test.rb',
      'test/functional/alias_test.rb',
      'test/functional/api_controller_test.rb',
      'test/functional/app_events_controller_test.rb',
      'test/functional/application_controller_test.rb',
      'test/functional/application_test.rb',
      'test/functional/authorizations_controller_test.rb',
      'test/functional/cartridges_controller_test.rb',
      'test/functional/cartridge_type_test.rb',
      'test/functional/cloud_user_test.rb',
      'test/functional/deployments_controller_test.rb',
      'test/functional/deployment_test.rb',
      'test/functional/descriptors_controller_test.rb',
      'test/functional/user_controller_test.rb'
    ]
  end

  Rake::TestTask.new :functionals2 => ['test:prepare'] do |t|
    t.libs << 'test'
    t.test_files = FileList[
      'test/functional/distributed_lock_test.rb',
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
      'test/functional/node_selection_plugin_test.rb',
      'test/functional/quickstarts_controller_test.rb',
      'test/functional/region_test.rb'
    ]
  end

  Rake::TestTask.new :functionals3 => ['test:prepare'] do |t|
    t.libs << 'test'
    t.test_files = FileList[
      'test/functional/rest_api_test.rb',
      'test/functional/sub_user_test.rb',
      'test/functional/usage_model_test.rb'
    ]
  end

  Rake::TestTask.new :functionals_ext1 => ['test:prepare'] do |t|
    t.libs << 'test'
    t.test_files = FileList[
      'test/functional_ext/alias_test.rb',
      'test/functional_ext/app_cartridge_events_test.rb',
      'test/functional_ext/app_cartridges_test.rb',
      'test/functional_ext/app_events_test.rb',
      'test/functional_ext/application_test.rb',
      'test/functional_ext/deployment_test.rb'
    ]
  end

  Rake::TestTask.new :functionals_ext2 => ['test:prepare'] do |t|
    t.libs << 'test'
    t.test_files = FileList[
      'test/functional_ext/domain_test.rb',
      'test/functional_ext/removed_nodes_app_fixup_test.rb',
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
  
  Rake::TestTask.new :oo_admin_scripts => ['test:prepare'] do |t|
    t.libs << "test"
    t.test_files = FileList[
      'test/functional/oo_*_test.rb',
      'test/functional_ext/oo_*_test.rb'
    ]
    t.verbose = true
  end

end
