# Steps specific to the php-5.3 cartridge.
require 'test/unit'
require 'test/unit/assertions'

include Test::Unit::Assertions

# NOTE: Assumes the test context is the basic steps provided
# by runtime_steps.rb
When /^I (add-alias|remove-alias) the php application$/ do |action|
  server_alias = "#{@app.name}-#{@account.name}.#{$alias_domain}"

  # todo: this is pretty ugly
  exit_status = @cart.run_hook action, 0, [ server_alias ]
  exit_status.should == 0
end

# NOTE: Assumes the test context is the basic steps provided
# by runtime_steps.rb
Then /^the php application will( not)? be aliased$/ do | negate |
  good_status = negate ? 1 : 0

  exit_status = -1
  StickShift::timeout(20) do
    begin
      sleep 1
      command = "/usr/bin/curl -L -H 'Host: #{@app.name}-#{@account.name}.#{$alias_domain}' -s http://localhost/health_check.php | /bin/grep -q -e '^1$'"
      exit_status = runcon command, $selinux_user, $selinux_role, $selinux_type
    end while exit_status != good_status
  end
  exit_status.should == good_status
end

When /^I (expose-port|conceal-port) the php application$/ do |action|
  @cart.run_hook action, 0
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
  app_home = "/var/lib/stickshift/#{gear_uuid}"
  uid = Etc.getpwnam(gear_uuid).uid
  gid = Etc.getpwnam(gear_uuid).gid
  mcs = libra_mcs_level(uid)
  se_context = "unconfined_u:object_r:libra_var_lib_t:#{mcs}"
  # Configure files (relative to app_home)
  configure_files = { "php-5.3" => ['root', 'root', '40755', se_context],
                    "php-5.3/" => ['root', 'root', '40755', se_context],
                    ".pearrc" => ['root', 'root', '100644', se_context],
                    "php-5.3/conf/" => ['root', 'root', '40755', se_context],
                    "php-5.3/conf/php.ini" => ['root', 'root', '100644', se_context],
                    "php-5.3/conf/magic" => ['root', 'root', '100644', se_context],
                    "php-5.3/conf.d/" => ['root', 'root', '40755', se_context],
                    "php-5.3/conf.d/stickshift.conf" => ['root', 'root', '100644', se_context],
                    "app-root/data/" => [gear_uuid, gear_uuid, '40755', se_context],
                    "php-5.3/logs/" => [gear_uuid, gear_uuid, '40755', se_context],
                    "php-5.3/phplib/pear/" => [gear_uuid, gear_uuid, '40755', se_context],
                    "app-root/data/" => [gear_uuid, gear_uuid, '40750', se_context],
                    "app-root/repo/" => [gear_uuid, gear_uuid, '40750', se_context],
                    "php-5.3/run/" => [gear_uuid, gear_uuid, '40755', se_context],
                    "php-5.3/run/httpd.pid" => [gear_uuid, gear_uuid, '100644', se_context],
                    "app-root/repo/php/index.php" => [gear_uuid, gear_uuid, '100664', se_context],
                    "php-5.3/sessions/" => [gear_uuid, gear_uuid, '40755', se_context], 
                    "php-5.3/tmp/" => [gear_uuid, gear_uuid, '40755', se_context]
                    } 
  configure_files.each do | file, permissions |
    raise "Invalid permissions for #{file}" unless mode?("#{app_home}/#{file}", permissions[2])
    raise "Invalid context for #{file}" unless context?("#{app_home}/#{file}", permissions[3])
    target_uid = Etc.getpwnam(permissions[0]).uid.to_i
    target_gid = Etc.getgrnam(permissions[1]).gid.to_i
    raise "Invalid ownership for #{file}" unless owner?("#{app_home}/#{file}", target_uid, target_gid)
  end
end
