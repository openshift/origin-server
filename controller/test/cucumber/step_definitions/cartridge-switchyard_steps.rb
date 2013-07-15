# step descriptions for MySQL cartridge behavior.

require 'fileutils'

Then /^the eap module configuration file will( not)? exist$/ do |negate|

  env_dir = "#{$home_root}/#{@gear.uuid}/switchyard/env"
  
  module_config_file = "#{env_dir}/OPENSHIFT_JBOSSEAP_MODULE_PATH"

  if negate
    assert_file_not_exists module_config_file
  else
    assert_file_exists module_config_file
  end
end

Then /^the as module configuration file will( not)? exist$/ do |negate|
  env_dir = "#{$home_root}/#{@gear.uuid}/switchyard/env"

  module_config_file = "#{env_dir}/OPENSHIFT_JBOSSAS_MODULE_PATH"

  if negate
    assert_file_not_exists module_config_file
  else
    assert_file_exists module_config_file
  end
end


