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
