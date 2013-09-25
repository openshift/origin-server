require 'rubygems'
require 'parseconfig'
require 'mcollective'

include MCollective::RPC
options = MCollective::Util.default_options

district_info_file = "/var/lib/openshift/.settings/district.info"

Given /^a new active district with first_uid (\d+) and max_uid (\d+)$/ do |first_uid, max_uid|
  # Clean up anything left over
  FileUtils.rm_f district_info_file
  uuid = SecureRandom.hex(16)
  @district = {:uuid => uuid, :active => 'true', :first_uid => first_uid, :max_uid => max_uid}
  mc = rpcclient("openshift", {:options => options})
  reply = mc.set_district(:uuid => uuid, :active => true, :first_uid => first_uid.to_i, :max_uid => max_uid.to_i)
  reply[0][:data][:exitcode].should be == 0
end

When /^the district is updated with first_uid (\d+) and max_uid (\d+)$/ do |first_uid, max_uid|
  @district[:first_uid] = first_uid
  @district[:max_uid] = max_uid
  mc = rpcclient("openshift", {:options => options})
  reply = mc.set_district_uid_limits(:uuid => @district[:uuid], :first_uid => first_uid.to_i, :max_uid => max_uid.to_i)
  reply[0][:data][:exitcode].should be == 0
end

Then /^the district info file should match the district$/ do
  assert_file_exist district_info_file

  config = ParseConfig.new district_info_file
  config['uuid'].should == @district[:uuid]
  config['active'].should == @district[:active] 
  config['first_uid'].should == @district[:first_uid]
  config['max_uid'].should == @district[:max_uid]
end

Then /^the file (.*) does( not)? exist$/ do |file, negate|
  if negate
    refute_file_exist file
  else
    assert_file_exist file
  end
end

Then /^remove the district info file/ do
  FileUtils.rm_f district_info_file
end
