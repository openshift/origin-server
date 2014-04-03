Then /^the ([^ ]+) ([^ ]+) marker will( not)? exist$/ do |cartridge_name, marker, negate|
  state_dir = ".#{cartridge_name.sub('-', '_')}_cartridge_state"

  marker_file = File.join($home_root, @gear.uuid, 'app-root', 'data', state_dir, marker)

  if negate
    refute_file_exist marker_file
  else
    assert_file_exist marker_file
  end
end

When /^the ([^ ]+) ([^ ]+) marker is removed$/ do |cartridge_name, marker|
  state_dir = ".#{cartridge_name.sub('-', '_')}_cartridge_state"

  marker_file = File.join($home_root, @gear.uuid, 'app-root', 'data', state_dir, marker)

  FileUtils.rm_f marker_file
  refute_file_exist marker_file
end


Then /^the ([^ ]+) ([^ ]+) marker will be ([^ ]+)$/ do |cartridge_name, marker, value|
  state_dir = ".#{cartridge_name.sub('-', '_')}_cartridge_state"

  marker_file = File.join($home_root, @gear.uuid, 'app-root', 'data', state_dir, marker)

  assert_file_exist marker_file

  assert_equal value, File.open(marker_file, "rb").read.chomp
end

When /^a new file is added and pushed to the client-created application repo$/ do
  Dir.chdir(@app.repo) do
    run "echo 'foo' >> cucumber_test_file"
    run 'git add .'
    run "git commit -m 'Test Change'"
    run("git push >> " + @app.get_log("git_push") + " 2>&1")
  end
end

Then /^the new file will (not )?be present in the (secondary )?gear app-root repo$/ do |negate, secondary|
  file = File.join($home_root, @app.uid, 'app-root', 'repo', 'cucumber_test_file')

  if secondary
    secondary_gear = @app.ssh_command("grep gear- haproxy/conf/haproxy.cfg | awk '{ print $2}' | sed 's#gear-##g'").split("-").first
    file = File.join($home_root, secondary_gear, 'app-root', 'repo', 'cucumber_test_file')
  end

  if negate
    refute_file_exist file
  else
    assert_file_exist file
  end
end

Then /^the ([^ ]+) ([^ ]+) marker will( not)? exist in the( plugin)? gear$/ do |cartridge_name, marker, negate, plugin|
  state_dir = ".#{cartridge_name.sub('-', '_')}_cartridge_state"

  marker_file = File.join($home_root, @app.uid, 'app-root', 'data', state_dir, marker)

  if plugin
    plugin_gear_uuid = IO.read(File.join($home_root, @app.uid, '.env', 'mock-plugin', 'OPENSHIFT_MOCK_PLUGIN_GEAR_UUID')).chomp
    plugin_gear_uuid.sub!(/export OPENSHIFT_MOCK_PLUGIN_GEAR_UUID=\'/, '')
    plugin_gear_uuid.chomp!('\'')
    marker_file = File.join($home_root, plugin_gear_uuid, 'app-root', 'data', state_dir, marker)
  end

  if negate
    refute_file_exist marker_file
  else
    assert_file_exist marker_file
  end  
end

Then /^the( plugin)? gear state will be (.*?)$/ do |plugin, state|
  state_file = File.join($home_root, @app.uid, 'app-root', 'runtime', '.state')
  if plugin
    plugin_gear_uuid = IO.read(File.join($home_root, @app.uid, '.env', 'mock-plugin', 'OPENSHIFT_MOCK_PLUGIN_GEAR_UUID')).chomp
    plugin_gear_uuid.sub!(/export OPENSHIFT_MOCK_PLUGIN_GEAR_UUID=\'/, '')
    plugin_gear_uuid.chomp!('\'')
    marker_file = File.join($home_root, plugin_gear_uuid, 'app-root', 'runtime', '.state')
  end
  gear_state = File.read(state_file).chomp
  assert_equal state, gear_state
end

When /^the minimum scaling parameter is set to (\d+)$/ do |min|
  rhc_ctl_scale(@app, min) 
end
