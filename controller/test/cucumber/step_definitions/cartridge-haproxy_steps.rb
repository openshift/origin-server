# step descriptions for HAProxy cartridge behavior.

require 'fileutils'

# Hack to ensure haproxy_ctld_daemon continues to work
ENV['BUNDLE_GEMFILE'] = nil

Given /^a new ([^ ]+) application, verify haproxy-1.4 using ([^ ]+) process$/ do |cart_name, proc_name|
  steps %Q{
    Given a new #{cart_name} type application
    Then a #{proc_name} process will be running
    
    When I embed a haproxy-1.4 cartridge into the application
    Then 0 process named haproxy will be running
    And the embedded haproxy-1.4 cartridge directory will exist
    And the haproxy configuration file will exist
    And the haproxy PATH override will exist

    When I destroy the application
    Then 0 processes named haproxy will be running
    And a #{proc_name} process will not be running
    And the embedded haproxy-1.4 cartridge directory will not exist
    And the haproxy configuration file will not exist
  }
end

Then /^the haproxy PATH override will( not)? exist$/ do |negate|
  path_location = "#{$home_root}/#{@gear.uuid}/.env/PATH"

  path_override = open(path_location).grep(/haproxy-1.4/)[0]

  unless negate
    path_override.should be_a(String)
  else
    path_override.should be_nil
  end
end

Then /^the haproxy configuration file will( not)? exist$/ do |negate|
  haproxy_user_root = "#{$home_root}/#{@gear.uuid}/haproxy-1.4"
  haproxy_config_file = "#{haproxy_user_root}/conf/haproxy.cfg.template"

  if negate
    assert_file_not_exists haproxy_config_file
  else
    assert_file_exists haproxy_config_file
  end
end
