# step descriptions for HAProxy cartridge behavior.

require 'fileutils'

# Hack to ensure haproxy_ctld_daemon continues to work
ENV['BUNDLE_GEMFILE'] = nil

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
    refute_file_exist haproxy_config_file
  else
    assert_file_exist haproxy_config_file
  end
end
