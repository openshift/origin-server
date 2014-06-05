# Steps specific to the php cartridge.
require 'test/unit'
require 'test/unit/assertions'

include Test::Unit::Assertions

# NOTE: Assumes the test context is the basic steps provided
# by runtime_steps.rb
Then /^the php application will( not)? be aliased$/ do | negate |
  good_status = negate ? 1 : 0

  exit_status = -1
  OpenShift::timeout(20) do
    begin
      sleep 1
      command = "/usr/bin/curl -L -H 'Host: #{@app.name}.#{$alias_domain}' -s http://localhost/health | /bin/grep -q -e '^1$'"
      exit_status = runcon command, $selinux_user, $selinux_role, $selinux_type
    end while exit_status != good_status
  end
  exit_status.should == good_status
end

Then /^the php application will( not)? be exposed$/ do | negate |
  exitcode, output = @cart.run_hook_output 'show-port', 0

  if negate
    assert_nil output[0].index('PROXY_PORT')
  else
    assert_not_nil output[0].index('PROXY_PORT')
  end
end

Then /^the php file permissions are correct/ do
  gear_uuid = @gear.uuid
  app_home = "/var/lib/openshift/#{gear_uuid}"
  uid = Etc.getpwnam(gear_uuid).uid
  gid = Etc.getpwnam(gear_uuid).gid
  mcs = get_mcs_level(uid)
  se_context = "unconfined_u:object_r:openshift_var_lib_t:#{mcs}"
  se_context2 = "unconfined_u:object_r:openshift_rw_file_t:#{mcs}"
  # Configure files (relative to app_home)
  configure_files = {
    "php" => [gear_uuid, gear_uuid, '40755', se_context],
    "php/" => [gear_uuid, gear_uuid, '40755', se_context],
    "php/conf/" => ['root', gear_uuid, '40755', se_context],
    "php/conf/magic" => ['root', 'root', '100644', se_context], # symlink to /etc/httpd/conf/magic
    "php/configuration/etc/" => ['root', gear_uuid, '40755', se_context],
    "php/configuration/etc/conf/" => ['root', gear_uuid, '100644', se_context],
    "php/configuration/etc/conf/*" => ['root', gear_uuid, '100644', se_context],
    "php/configuration/etc/conf.d/" => ['root', gear_uuid, '100644', se_context],
    "php/configuration/etc/conf.d/php.conf" => ['root', gear_uuid, '100644', se_context],
    "php/configuration/etc/conf.d/openshift.conf" => [gear_uuid, gear_uuid, '100644', se_context],
    "php/configuration/etc/conf.d/performance.conf" => [gear_uuid, gear_uuid, '100644', se_context],
    "php/configuration/etc/conf.d/passenv.conf" => [gear_uuid, gear_uuid, '100644', se_context],
    "php/configuration/etc/php.d" => ['root', gear_uuid, '100644', se_context],
    "php/configuration/etc/php.d/apc.ini" => [gear_uuid, gear_uuid, '100644', se_context],
    "php/configuration/etc/php.d/xdebug.ini" => [gear_uuid, gear_uuid, '100644', se_context],
    "php/configuration/etc/php.d/locked-*" => ['root', gear_uuid, '100644', se_context],
    "php/configuration/etc/php.ini" => [gear_uuid, gear_uuid, '100644', se_context],
    "php/logs/" => [gear_uuid, gear_uuid, '40755', se_context],
    "php/phplib/pear/" => [gear_uuid, gear_uuid, '40755', se_context],
    "php/run/" => [gear_uuid, gear_uuid, '40755', se_context],
    "php/run/httpd.pid" => [gear_uuid, gear_uuid, '100644', se_context],
    "php/sessions/" => [gear_uuid, gear_uuid, '40755', se_context],
    "php/tmp/" => [gear_uuid, gear_uuid, '40755', se_context],
    "app-root/data/" => [gear_uuid, gear_uuid, '40750', se_context2],
    "app-root/repo/" => [gear_uuid, gear_uuid, '40750', se_context],
    ".gem" => [gear_uuid, gear_uuid, '40750', se_context], # see https://bugzilla.redhat.com/show_bug.cgi?id=974632
    ".pearrc" => ['root', gear_uuid, '100644', se_context],
  }
  configure_files.each do | pattern, permissions |
    Dir.glob(pattern).each do | file |
      user, group, mode, context = permissions
      raise "Invalid permissions for #{file}" unless mode?("#{app_home}/#{file}", mode)
      raise "Invalid context for #{file}" unless context?("#{app_home}/#{file}", context)
      target_uid = Etc.getpwnam(user).uid.to_i
      target_gid = Etc.getgrnam(group).gid.to_i

      raise "Invalid ownership for #{file}" unless owner?("#{app_home}/#{file}", target_uid, target_gid)
    end
  end
end

When /^I remove all files from repo directory$/ do
    Dir.chdir(@app.repo) do
      run("git rm -r *")
      run("git commit -am 'Test commit - Remove all files'")
    end
end

When /^I create ([^ ]*\.php) file in the ([^ ]*) repo directory$/ do | file, directory |
    Dir.chdir(@app.repo) do
      run("mkdir -p #{directory}")
      run("echo '<?php echo \"Welcome to OpenShift\";' > #{directory}/#{file}")
      run("git add #{directory}/#{file}")
      run("git commit -am 'Test commit - Create #{directory}/#{file} file'")
      run("git push >> " + @app.get_log("git_push_php_create_file") + " 2>&1")
    end
end

Then /^the (.*) url[s]? should( not)? be accessible$/ do | urls, negate |
    urls.split.each do | url |
      http_code = `/usr/bin/curl -s -H 'Host: #{@app.name}-#{@app.namespace}.#{$domain}' -o /dev/null -w '%{http_code}' -s 'http://localhost/#{url}'`
      raise "Invalid HTTP CODE #{http_code} for #{url}" unless (http_code == "200") ^ negate
    end
end


Then /^the php module ([^\"]*) will (not )?be loaded$/ do |php_module, negate|
  command = "ssh 2>/dev/null -o BatchMode=yes -o StrictHostKeyChecking=no -tt #{@app.uid}@#{@app.name}-#{@app.namespace}.#{$domain} " +  "php -m"
  $logger.info("About to execute command:'#{command}'")
  output_buffer=[]
  exit_code = run(command,output_buffer)
  raise "Cannot ssh into the application with #{@app.uid}. Running command: '#{command}' returns: \n Exit code: #{exit_code} \nOutput message:\n #{output_buffer[0]}" unless exit_code == 0
  pattern="\n#{php_module}[\r\n]"
  if negate
    output_buffer[0].should_not match(/#{pattern}/)
  else
    output_buffer[0].should match(/#{pattern}/)
  end
end
