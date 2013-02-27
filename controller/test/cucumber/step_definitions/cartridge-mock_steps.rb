Given /^a v2 default node$/ do
  assert_file_exists '/var/lib/openshift/.settings/v2_cartridge_format'
end

Then /^the ([^ ]+) ([^ ]+) marker will( not)? exist$/ do |cartridge_name, marker, negate|
  state_dir = ".#{cartridge_name.sub('-', '_')}_cartridge_state"

  marker_file = File.join($home_root, @gear.uuid, 'app-root', 'data', state_dir, marker)

  if negate
    assert_file_not_exists marker_file
  else
    assert_file_exists marker_file
  end
end

Then /^the ([^ ]+) ([^ ]+) marker will be ([^ ]+)$/ do |cartridge_name, marker, value|
  state_dir = ".#{cartridge_name.sub('-', '_')}_cartridge_state"

  marker_file = File.join($home_root, @gear.uuid, 'app-root', 'data', state_dir, marker)

  assert_file_exists marker_file

  assert_equal value, File.open(marker_file, "rb").read.chomp
end

Then /^the ([^ ]+) ([^ ]+) env entry will( not)? exist$/ do |cartridge_name, variable, negate|
  cart_env_var_will_exist(cartridge_name, variable, negate)
end

Then /^the platform-created default environment variables will exist$/ do
  app_env_var_will_exist('APP_DNS')
  app_env_var_will_exist('APP_NAME')
  app_env_var_will_exist('APP_UUID')
  app_env_var_will_exist('DATA_DIR')
  app_env_var_will_exist('REPO_DIR')
  app_env_var_will_exist('GEAR_DNS')
  app_env_var_will_exist('GEAR_NAME')
  app_env_var_will_exist('GEAR_UUID')
  app_env_var_will_exist('TMP_DIR')
  app_env_var_will_exist('HOMEDIR')
  app_env_var_will_exist('HISTFILE', false)
  app_env_var_will_exist('PATH', false)
end

Then /^the mock cartridge private endpoints will be exposed$/ do
  app_env_var_will_exist('MOCK_EXAMPLE_IP1')
  app_env_var_will_exist('MOCK_EXAMPLE_PORT1')
  app_env_var_will_exist('MOCK_EXAMPLE_IP2')
  app_env_var_will_exist('MOCK_EXAMPLE_PORT2')
  app_env_var_will_exist('MOCK_EXAMPLE_PORT3')
  app_env_var_will_exist('MOCK_EXAMPLE_PORT4')
end

Then /^the mock-plugin cartridge private endpoints will be (exposed|concealed)$/ do |action|
  vars = %w(MOCK_PLUGIN_EXAMPLE_IP1 MOCK_PLUGIN_EXAMPLE_PORT1)
  
  vars.each do |var|
    case action
    when 'exposed'
      app_env_var_will_exist(var)
    when 'concealed'
      app_env_var_will_not_exist(var)
    end
  end
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


def cart_env_var_will_exist(cart_name, var_name, negate = false)
  var_name = "OPENSHIFT_#{var_name}"

  var_file_path = File.join($home_root, @gear.uuid, cart_name, 'env', var_name)

  if negate
    assert_file_not_exists var_file_path
  else
    assert_file_exists var_file_path
    assert((File.stat(var_file_path).size > 0), "#{var_file_path} is empty")
  end
end
