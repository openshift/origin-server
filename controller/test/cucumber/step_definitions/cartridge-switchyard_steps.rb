# step descriptions for MySQL cartridge behavior.

require 'fileutils'

Then /^the eap module configuration file will( not)? exist$/ do |negate|

  env_dir = "#{$home_root}/#{@gear.uuid}/switchyard/env"
  
  module_config_file = "#{env_dir}/OPENSHIFT_JBOSSEAP_MODULE_PATH"

  if negate
    refute_file_exist module_config_file
  else
    assert_file_exist module_config_file
  end
end

Then /^the as module configuration file will( not)? exist$/ do |negate|
  env_dir = "#{$home_root}/#{@gear.uuid}/switchyard/env"

  module_config_file = "#{env_dir}/OPENSHIFT_JBOSSAS_MODULE_PATH"

  if negate
    refute_file_exist module_config_file
  else
    assert_file_exist module_config_file
  end
end


