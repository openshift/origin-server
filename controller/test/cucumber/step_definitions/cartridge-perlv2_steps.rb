Then /^the ([^ ]+) ([^ ]+) marker will( not)? exist$/ do |cartridge_name, marker, negate|
  state_dir = ".#{cartridge_name.sub('-', '_')}_cartridge_state"

  marker_file = File.join($home_root, @gear.uuid, 'app-root', 'data', state_dir, marker)

  if negate
    assert_file_not_exists marker_file
  else
    assert_file_exists marker_file
  end
end

Then /^the perl cartridge private endpoints will be exposed$/ do
  app_env_var_will_exist('PERL_IP')
  app_env_var_will_exist('PERL_PORT')
end

Then /^the perl-plugin cartridge private endpoints will be concealed$/ do
  app_env_var_will_not_exist('PERL_PLUGIN_EXAMPLE_IP1')
  app_env_var_will_not_exist('PERL_PLUGIN_EXAMPLE_PORT1')
end

def app_env_var_will_exist(var_name, prefix = true)
  if prefix
    var_name = "OPENSHIFT_#{var_name}"
  end

  var_file_path = File.join($home_root, @gear.uuid, '.env', var_name)

  assert_file_exists var_file_path
end

def app_env_var_will_not_exist(var_name, prefix = true)
  if prefix
    var_name = "OPENSHIFT_#{var_name}"
  end

  var_file_path = File.join($home_root, @gear.uuid, '.env', var_name)

  assert_file_not_exists var_file_path
end

