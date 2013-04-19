Then /^the ([^ ]+) ([^ ]+) marker will( not)? exist$/ do |cartridge_name, marker, negate|
  state_dir = ".#{cartridge_name.sub('-', '_')}_cartridge_state"

  marker_file = File.join($home_root, @gear.uuid, 'app-root', 'data', state_dir, marker)

  if negate
    assert_file_not_exists marker_file
  else
    assert_file_exists marker_file
  end
end

When /^the ([^ ]+) ([^ ]+) marker is removed$/ do |cartridge_name, marker|
  state_dir = ".#{cartridge_name.sub('-', '_')}_cartridge_state"

  marker_file = File.join($home_root, @gear.uuid, 'app-root', 'data', state_dir, marker)

  FileUtils.rm_f marker_file
  assert_file_not_exists marker_file  
end


Then /^the ([^ ]+) ([^ ]+) marker will be ([^ ]+)$/ do |cartridge_name, marker, value|
  state_dir = ".#{cartridge_name.sub('-', '_')}_cartridge_state"

  marker_file = File.join($home_root, @gear.uuid, 'app-root', 'data', state_dir, marker)

  assert_file_exists marker_file

  assert_equal value, File.open(marker_file, "rb").read.chomp
end

When /^a new file is added and pushed to the client-created application repo$/ do
  Dir.chdir(@app.repo) do
    run "echo 'foo' >> cucumber_test_file"
    run 'git add .'
    run "git commit -m 'Test Change'"
    push_output = `git push`
    $logger.info("Push output:\n#{push_output}")
  end
end

Then /^the new file will (not )?be present in the (secondary )?gear app-root repo$/ do |negate, secondary|
  file = File.join($home_root, @app.uid, 'app-root', 'repo', 'cucumber_test_file')

  if secondary
    secondary_gear = @app.ssh_command("grep gear- haproxy/conf/haproxy.cfg | awk '{ print $2}' | sed 's#gear-##g'")

    file = File.join($home_root, secondary_gear, 'app-root', 'repo', 'cucumber_test_file')
  end

  if negate
    assert_file_not_exists file
  else
    assert_file_exists file
  end
end

Then /^the ([^ ]+) ([^ ]+) marker will( not)? exist in the( plugin)? gear$/ do |cartridge_name, marker, negate, plugin|
  state_dir = ".#{cartridge_name.sub('-', '_')}_cartridge_state"

  marker_file = File.join($home_root, @app.uid, 'app-root', 'data', state_dir, marker)

  if plugin
    plugin_gear_uuid = IO.read(File.join($home_root, @app.uid, '.env', '.uservars', 'OPENSHIFT_MOCK_PLUGIN_GEAR_UUID')).chomp
    plugin_gear_uuid.sub!(/export OPENSHIFT_MOCK_PLUGIN_GEAR_UUID=\'/, '')
    plugin_gear_uuid.chomp!('\'')
    marker_file = File.join($home_root, plugin_gear_uuid, 'app-root', 'data', state_dir, marker)
  end

  if negate
    assert_file_not_exists marker_file
  else
    assert_file_exists marker_file
  end  
end

When /^the minimum scaling parameter is set to (\d+)$/ do |min|
  rhc_ctl_scale(@app, min) 
end
