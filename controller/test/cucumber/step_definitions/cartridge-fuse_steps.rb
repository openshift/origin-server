require 'rubygems'
require 'uri'
require 'fileutils'

include AppHelper

When /^I create a (.+) app$/ do |type|
   
  @app = TestApp.create_unique(type)
  @apps ||= []
  @apps << @app.name
  register_user(@app.login, @app.password) if $registration_required
  if rhc_create_domain(@app)
    rhc_create_app(@app, false, "--no-git")
  end
  raise "Could not create domain: #{@app.create_domain_code}" unless @app.create_domain_code == 0
  raise "Could not create application #{@app.create_app_code}" unless @app.create_app_code == 0

  @test_apps_hash ||= {}
  @test_apps_hash[@app.name] = @app
end

When /^a container named (.+) is created using the (.+) profile$/ do |container_name, profile|
  container_app=TestApp.create_app_from_params(@app.namespace,@app.login, @app.type, @app.password,false)
  container_app.name=container_name
  container_app.persist
  run "echo -e \"Host #{container_app.hostname}\n\tStrictHostKeyChecking no\n\" >> ~/.ssh/config"

  cmd="\\$OPENSHIFT_FUSE_DIR/container/bin/client \"\\\"wait-for-service io.fabric8.api.FabricService\\\"\""
  @app.ssh_command(cmd)
  
  cmd="\\$OPENSHIFT_FUSE_DIR/container/bin/client \"\\\"fabric:container-create-openshift --login #{@app.login} --password #{@app.password} --server-url localhost --profile #{profile} #{container_name}\\\"\""
  count=0;
  begin
    res=@app.ssh_command(cmd)
    count+=1
    sleep 10
  end while (res.include?"Command not found") && count<30

  res=`rhc app show #{container_name} -l #{@app.login} -p #{@app.password} --insecure`
  container_app.update_uid(res) 
  container_app.persist 

end

Then /^(\d+) containers should exist$/ do |count|
  for i in 0..20
    containers=@app.ssh_command("\\$OPENSHIFT_FUSE_DIR/container/bin/client container-list | grep success | wc -l")
    break if(containers==count) 
    sleep 10
  end
  containers.should ==count
end

Then /^(\d+) camel route(s)? should exist on app (.+)$/ do |count, skip, app_name|  
  TestApp.find_on_fs.each do |app|
    if app.name == app_name
      @app = app
      break
    end
  end
#  res=`rhc app show #{app_name} -l #{@app.login} -p #{@app.password} --insecure`
#  @app.update_uid(res) 
#  @app.persist 
  for i in 0..20
    containers=@app.ssh_command("\\$OPENSHIFT_FUSE_DIR/container/bin/client camel:route-list | grep Started | wc -l")
    break if(containers==count)
    sleep 10
  end
  containers.should ==count
end

When /^input files are copied from (.+) to  (.+)$/ do |from, to|
  @app.ssh_command("\"cp #{from} #{to}\"")
end

Then /^the app directory (.+) should contain (.+)$/ do |dir, file_list|
  files=file_list.split(/\s/)
  files.each do |file|
    found=false
    tries=0
    while !found && tries < 10 do
      $logger.debug("Checking for presence of file #{file} in #{dir}")
      find=@app.ssh_command("\"find #{dir} -path \\*#{file}\"")
      $logger.debug("Find returned #{find}")
      found=true if find.include?(file)
      sleep 2 if !found
      tries+=1
    end
    find.should match(/#{file}/)
  end
end
