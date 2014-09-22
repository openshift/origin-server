require 'rubygems'
require 'uri'
require 'fileutils'

include AppHelper

Given /^an existing (.+) application with an embedded (.*) cartridge$/ do |type, embed|
  TestApp.find_on_fs.each do |app|
    if app.type == type and app.embed.include?(embed)
      @app = app
      break
    end
  end

  @app.should_not be_nil
end

Given /^an existing (.+) application( without an embedded cartridge)?$/ do |type, ignore|
  TestApp.find_on_fs.each do |app|
    if app.type == type and app.embed.empty?
      @app = app
      @app.update_jenkins_info if type.start_with?("jenkins")
      break
    end
  end

  @app.should_not be_nil
end

Given /^an existing application named (.+)$/ do |name|
  TestApp.find_on_fs.each do |app|
    if app.name == name
      @app = app
      break
    end
  end

  @app.should_not be_nil
end

Given /^a new client created( scalable)? (.+) application$/ do |scalable, type|
  @app = TestApp.create_unique(type, nil, scalable)
  @apps ||= []
  @apps << @app.name
  register_user(@app.login, @app.password) if $registration_required
  if rhc_create_domain(@app)
    if scalable
      rhc_create_app(@app, true, '-s')
    else
      rhc_create_app(@app)
    end
  end
  raise "Could not create domain: #{@app.create_domain_code}" unless @app.create_domain_code == 0
  raise "Could not create application #{@app.create_app_code}" unless @app.create_app_code == 0

  @test_apps_hash ||= {}
  @test_apps_hash[@app.name] = @app
end

Given /^a new client created( scalable)? (.+) application named ([^\s]+)$/ do |scalable, type, app_name|
  @app = TestApp.create_unique(type, nil, scalable)
  @apps ||= []
  @apps << @app.name
  register_user(@app.login, @app.password) if $registration_required
  if rhc_create_domain(@app)
    if scalable
      rhc_create_app(@app, true, '-s')
    else
      rhc_create_app(@app)
    end
  end
  raise "Could not create domain: #{@app.create_domain_code}" unless @app.create_domain_code == 0
  raise "Could not create application #{@app.create_app_code}" unless @app.create_app_code == 0

  @test_apps_hash ||= {}
  @test_apps_hash[app_name] = @app
end


Then /^creating a new client( scalable)? (.+) application should fail$/ do |scalable, type|
  @app = TestApp.create_unique(type, nil, scalable)
  @apps ||= []
  register_user(@app.login, @app.password) if $registration_required
  if rhc_create_domain(@app)
    if scalable
      rhc_create_app(@app, true, '-s')
    else
      rhc_create_app(@app)
    end
  end
  if  @app.create_app_code == 0
    raise "Expecting to fail in creating a new application but successfully created the application with uuid  #{@app.uuid}"
  end
  @apps << @app.name
end

Given /^a new client created( scalable)? (.+) application named "([^\"]*)" in the namespace "([^\"]*)"$/ do |scalable, type, app_name, namespace_key|
  @unique_namespace_apps_hash ||= {}
  @app = TestApp.create_unique(type, nil, scalable)
  @test_apps_hash ||= {}

  register_user(@app.login, @app.password) if $registration_required
  if rhc_create_domain(@app)
    if scalable
      rhc_create_app(@app, true, '-s')
    else
      rhc_create_app(@app)
    end
  end

  raise "Could not create domain: #{@app.create_domain_code}" unless @app.create_domain_code == 0
  raise "Could not create application #{@app.create_app_code}" unless @app.create_app_code == 0

 @test_apps_hash[app_name] = @app
 @unique_namespace_apps_hash[namespace_key]= @app
 @apps ||= []
 @apps << @app.name
end

Given /^an additional client created( scalable)? (.+) application named "([^\"]*)" in the namespace "([^\"]*)"$/ do |scalable, type, app_name, namespace_key|

 if @unique_namespace_apps_hash[namespace_key].nil?
  raise "Cannot add new application because the namespace /'#{namespace_key}/' does not exist in the hash of namespaces"
 else
  previous_app = @unique_namespace_apps_hash[namespace_key]
  @app =  TestApp.create_app_from_params(previous_app.namespace, previous_app.login, type, previous_app.password, scalable)
  register_user(@app.login, @app.password) if $registration_required
  if scalable
     rhc_create_app(@app, true, '-s')
  else
     rhc_create_app(@app)
  end
 end

 raise "Could not create application #{@app.create_app_code}" unless @app.create_app_code == 0
 @test_apps_hash ||= {}
 @test_apps_hash[app_name] = @app
 @apps ||= []
 @apps << @app.name

end

When /^(\d+)( scalable)? (.+) applications are created$/ do |app_count, scalable, type|
  # Create our domain and apps
  @apps = app_count.to_i.times.collect do
    app = TestApp.create_unique(type)
    register_user(app.login, app.password) if $registration_required
    if rhc_create_domain(app)
      opts = scalable ? "-s" : ""
      result = rhc_create_app(app, true, opts)
      app.update_jenkins_info if type.start_with?("jenkins")
    end
    raise "Could not create domain: #{app.create_domain_code}"  unless app.create_domain_code == 0
    raise "Could not create application #{app.create_app_code}: #{result}" unless app.create_app_code == 0
    app
  end
end

When /^the submodule is added$/ do
  Dir.chdir(@app.repo) do
    # Add a submodule created in devenv and link the index file
    run("git submodule add #{$submodule_repo_dir}")
    run("REPLACE=`cat submodule_test_repo/index`; sed -i \"s/OpenShift/${REPLACE}/\" #{@app.get_index_file}")
    run("git commit -a -m 'Test submodule change'")
    run("git push >> " + @app.get_log("git_push") + " 2>&1")
  end
end

When /^the embedded (.*) cartridge is added$/ do |type|
  rhc_embed_add(@app, type)
end

When /^the embedded (.*) cartridge is removed$/ do |type|
  rhc_embed_remove(@app, type)
end

When /^a new environment variable key=(.*) value=(.*) is added$/ do |key, value|
  rhc_set_env(@app,key,value)
end

When /^the application is changed$/ do
  Dir.chdir(@app.repo) do
    @update = "TEST"

    # Make a change to the app index file
    run("sed -i 's/Welcome/#{@update}/' #{@app.get_index_file}")
    run("git commit -a -m 'Test change'")
    run("git push >> " + @app.get_log("git_push") + " 2>&1")
  end
end

When /^the application uses mysql$/ do
  # the mysql file path is NOT relative to the app repo
  # so, fetch the mysql file before the Dir.chdir
  mysql_file = @app.get_mysql_file

  Dir.chdir(@app.repo) do
    # Copy the MySQL file over the index and replace the variables
    FileUtils.cp mysql_file, @app.get_index_file

    # Make a change to the app index file
    run("sed -i 's/HOSTNAME/#{@app.mysql_hostname}/' #{@app.get_index_file}")
    run("sed -i 's/USER/#{@app.mysql_user}/' #{@app.get_index_file}")
    run("sed -i 's/PASSWORD/#{@app.mysql_password}/' #{@app.get_index_file}")
    run("git commit -a -m 'Test change'")
    run("git push >> " + @app.get_log("git_push_mysql") + " 2>&1")
  end
end

When /^the application is stopped$/ do
  rhc_ctl_stop(@app)
end

When /^the application is started$/ do
  rhc_ctl_start(@app)
end

When /^the application is aliased$/ do
  rhc_add_alias(@app)
end

When /^the application is unaliased$/ do
  rhc_remove_alias(@app)
end

When /^the application is restarted$/ do
  rhc_ctl_restart(@app)
end

When /^the application is destroyed$/ do
  rhc_ctl_destroy(@app)
end

When /^the application namespace is updated$/ do
  rhc_update_namespace(@app)
end

When /^I snapshot the application$/ do
  rhc_snapshot(@app)
  File.exist?(@app.snapshot).should be_true
  File.size(@app.snapshot).should > 0
end

When "I preserve the current snapshot" do
  assert_file_exist @app.snapshot
  tmpdir = Dir.mktmpdir

  @saved_snapshot = File.join(tmpdir,File.basename(@app.snapshot))
  FileUtils.cp(@app.snapshot,@saved_snapshot)
end

When /^I tidy the application$/ do
  rhc_tidy(@app)
end

When /^I reload the application$/ do
  rhc_reload(@app)
end

When /^I restore the application( from a preserved snapshot)?$/ do |preserve|
  if preserve
    @app.snapshot = @saved_snapshot
  end
  assert_file_exist @app.snapshot
  File.size(@app.snapshot).should > 0

  file_list = `tar ztf #{@app.snapshot}`
  ["#{@app.name}_ctl.sh", "openshift.conf", "httpd.pid"].each {|file|
    assert ! file_list.include?(file), "Found illegal file \'#{file} in snapshot"
  }
  assert file_list.include?('app-root/runtime'), "Snapshot missing required files"

  rhc_restore(@app)
end

Then /^the application should respond to the alias$/ do
  @app.is_accessible?(false, 120, "#{@app.name}-#{@app.namespace}.#{$alias_domain}").should be_true
end

Then /^the applications should( not)? be accessible?$/ do |negate|
  @apps.each do |app|
    if negate
      app.is_accessible?.should be_false
      app.is_accessible?(true).should be_false
    else
      app.is_accessible?.should be_true
      app.is_accessible?(true).should be_true
    end
  end
end

Then /^the applications should display default content on first attempt$/ do
  @apps.each do |app|
    # Check for "Welcome to OpenShift"
    body = app.connect(false,1,5)
    body.should match(/Welcome to OpenShift/)
    body = app.connect(true,1,5)
    body.should match(/Welcome to OpenShift/)
  end
end

When /^the applications are destroyed$/ do
  @apps.each do |app|
    rhc_ctl_destroy(app)
  end
end

Then /^the applications should be accessible via node\-web\-proxy$/ do
  @apps.each do |app|
    app.is_accessible?(false, 120, nil, 8000).should be_true
    app.is_accessible?(true, 120, nil, 8443).should be_true
  end
end

Then /^the applications should be temporarily unavailable$/ do
  @apps.each do |app|
    app.is_temporarily_unavailable?.should be_true
  end
end

Then /^the mysql response is successful$/ do
  60.times do |i|
    body = @app.connect
    break if body and body =~ /Success/
    sleep 1
  end

  # Check for Success
  body = @app.connect
  body.should match(/Success/)
end

Then /^it should be updated successfully$/ do
  60.times do |i|
    body = @app.connect
    break if body and body =~ /#{@update}/
    sleep 1
  end

  # Make sure the update is present
  body = @app.connect
  body.should_not be_nil
  body.should match(/#{@update}/)
end

Then /^the submodule should be deployed successfully$/ do
  60.times do |i|
    body = @app.connect
    break if body and body =~ /Submodule/
    sleep 1
  end

  # Make sure the update is present
  body = @app.connect
  body.should_not be_nil
  body.should match(/Submodule/)
end

Then /^the application should be accessible$/ do
  assert_application_accessible(@app)
end

Then /^the (.+) application should (not )?be accessible$/ do |app_name, negate|
  app = @test_apps_hash[app_name]
  assert_application_accessible(app, negate)
end

Then /^the application should (not )?be accessible with path (.+)$/ do |negate, path|
  assert_application_path_accessible(@app, negate, path)
end

def assert_application_accessible(app, negate=false)
  if negate
    app.is_accessible?(false, 1).should be_false
    app.is_accessible?(true, 1).should be_false
  else
    app.is_accessible?.should be_true
    app.is_accessible?(true).should be_true
  end
end

def assert_application_path_accessible(app, negate=false, path=nil)
  if negate
    app.is_path_accessible?(false, 1, path).should be_false
    app.is_path_accessible?(true, 1, path).should be_false
  else
    app.is_path_accessible?(false, 120, path).should be_true
    app.is_path_accessible?(true, 120, path).should be_true
  end
end

Then /^the cartridge (.+) status should be (.+)$/ do |cartridge, status|
  result = rhc_get_app_status(@app, cartridge, false)
  result.should =~ /#{status}/
end

Then /^the application should display default content on first attempt$/ do
  # Check for "Welcome to OpenShift"
  body = @app.connect(false,1,5)
  body.should match(/Welcome to OpenShift/)
  body = @app.connect(true,1,5)
  body.should match(/Welcome to OpenShift/)
end

Then /^the application should not be accessible$/ do
  @app.is_inaccessible?.should be_true
end

Then /^the application should not be accessible via node\-web\-proxy$/ do
  @app.is_inaccessible?(60, 8000).should be_true
end

Then /^the application should be assigned to the supplementary groups? "([^\"]*)" as shown by the node's \/etc\/group$/ do | supplementary_groups|
  added_supplementary_group = supplementary_groups.split(",")

  added_supplementary_group.each do |group|
    output_buffer = []
    exit_code = run("cat /etc/group | grep #{group}:x | grep #{@app.uid}", output_buffer)
    if output_buffer[0] == ""
      raise "The user for application with uid #{@app.uid} is not assigned to group \'#{group}\'"
    end
  end
end

Then /^the application has the group "([^\"]*)" as a secondary group$/ do |supplementary_group|
 command = "ssh 2>/dev/null -o BatchMode=yes -o StrictHostKeyChecking=no -tt #{@app.uid}@#{@app.name}-#{@app.namespace}.#{$domain} " +  "groups"
 $logger.info("About to execute command:'#{command}'")
 output_buffer=[]
 exit_code = run(command,output_buffer)
 raise "Cannot ssh into the application with #{@app.uid}. Running command: '#{command}' returns: \n Exit code: #{exit_code} \nOutput message:\n #{output_buffer[0]}" unless exit_code == 0
 if !(output_buffer[0].include? supplementary_group)
   raise "The application with uuid #{@app.uid} is not assigned to group #{supplementary_group}."
 end
end

Then /^the haproxy-status page will( not)? be responding$/ do |negate|
  expected_status = negate ? 1 : 0

  command = "/usr/bin/curl -s -H 'Host: #{@app.name}-#{@app.namespace}.#{$domain}' -s 'http://localhost/haproxy-status/;csv' | /bin/grep -q -e '^stats,FRONTEND'"
  exit_status = runcon command, 'unconfined_u', 'unconfined_r', 'unconfined_t'
  exit_status.should == expected_status
end

Then /^the gear members will be (UP|DOWN)$/ do |state|
  found = nil

  OpenShift::timeout(120) do
    while found != 0
      found = gear_up?("#{@app.name}-#{@app.namespace}.#{$domain}", state)
      sleep 1
    end
  end
  assert_equal 0, found, "Could not find valid gear"
end

Then /^(at least )?(\d+) gears will be in the cluster$/ do |fuzzy, expected|
  expected = expected.to_i
  actual = 0

  gear_test = lambda { | expected, actual| return actual != expected }

  if fuzzy
    gear_test = lambda { |expected, actual| return actual < expected }
  end


  host = "'Host: #{@app.name}-#{@app.namespace}.#{$domain}'"
  OpenShift::timeout(300) do
    while gear_test.call(expected, actual)
      sleep 1

      $logger.debug("============ GEAR CSV #{Process.pid} ============")
      results = `/usr/bin/curl -s -H #{host} -s 'http://localhost/haproxy-status/;csv'`.chomp()
      $logger.debug(results)
      $logger.debug("============ GEAR CSV END ============")

      actual = results.split("\n").find_all {|l| l.start_with?('express,gear')}.length() + results.split("\n").find_all {|l| l.start_with?('express,local')}.length()
      $logger.debug("Gear count: waiting for #{actual} to be #{'at least ' if fuzzy}#{expected}")
    end
  end

  assert_equal false, gear_test.call(expected, actual)
end

def gear_up?(hostname, state='UP')
  csv = `/usr/bin/curl -s -H 'Host: #{hostname}' -s 'http://localhost/haproxy-status/;csv'`
  assert $?.success?, "Failed to retrieve haproxy-status results: #{csv}"
  $logger.debug("============ GEAR CSV #{Process.pid} ============")
  $logger.debug(csv)
  $logger.debug('============ GEAR CSV END ============')
  found = 1
  csv.split.each do | haproxy_worker |

    worker_attrib_array = haproxy_worker.split(',')
    if worker_attrib_array[17] and worker_attrib_array[1].to_s == "local-gear" and worker_attrib_array[17].to_s.start_with?(state)
      $logger.debug("Found: #{worker_attrib_array[1]} - #{worker_attrib_array[17]}")
      found = 0
    elsif worker_attrib_array[17] and worker_attrib_array[1].to_s.start_with?('gear') and not worker_attrib_array[17].to_s.start_with?(state)
      return 1
    end
  end
  $logger.debug("No gears found")
  return found
end

When /^JAVA_OPTS_EXT is available$/ do
  user_vars =  File.join($home_root, @app.uid, '.env', 'user_vars')
  FileUtils.mkpath(user_vars)
  env = File.join(user_vars, 'JAVA_OPTS_EXT')

  IO.write(env, '-Dcucumber=true', 0, mode: 'w', perm: 0644)
end

When /^the jvm is using JAVA_OPTS_EXT$/ do
  %x(pgrep -fl 'java.*Dcucumber=true')
  assert_equal(0, $?.exitstatus, 'JAVA_OPTS_EXT is not being used')
end

And /^I sleep (.+) seconds/ do |seconds|
  sleep seconds.to_i
end
