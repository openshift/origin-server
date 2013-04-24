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

Given /^a new client created( scalable)? (.+) application$/ do |scalable, type|
  @app = TestApp.create_unique(type, 'test', scalable)
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
end

When /^(\d+)( scalable)? (.+) applications are created$/ do |app_count, scalable, type|
  # Create our domain and apps
  @apps = app_count.to_i.times.collect do
    app = TestApp.create_unique(type)
    register_user(app.login, app.password) if $registration_required
    if rhc_create_domain(app)
      opts = scalable ? "-s" : ""
      rhc_create_app(app, true, opts)
      app.update_jenkins_info if type.start_with?("jenkins")
    end
    raise "Could not create domain: #{app.create_domain_code}"  unless app.create_domain_code == 0
    raise "Could not create application #{app.create_app_code}" unless app.create_app_code == 0
    app
  end
end

When /^the submodule is added$/ do
  Dir.chdir(@app.repo) do
    # Add a submodule created in devenv and link the index file
    run("git submodule add /root/submodule_test_repo")
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

When /^I tidy the application$/ do
  rhc_tidy(@app)
end

When /^I reload the application$/ do
  rhc_reload(@app)
end

When /^I restore the application$/ do
  assert_file_exists @app.snapshot
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

Then /^the applications should be accessible?$/ do
  @apps.each do |app|
    app.is_accessible?.should be_true
    app.is_accessible?(true).should be_true
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
  @app.is_accessible?.should be_true
  @app.is_accessible?(true).should be_true
end

Then /^the application should not be accessible$/ do
  @app.is_inaccessible?.should be_true
end


Then /^the application should not be accessible via node\-web\-proxy$/ do
  @app.is_inaccessible?(60, 8000).should be_true
end
