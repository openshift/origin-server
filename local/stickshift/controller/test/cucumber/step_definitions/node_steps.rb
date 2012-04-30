# 
# 
# Steps that can be used to check applications installed on a server (node)
#
#require 'etc'

require 'open4'


# Controller cartridge command paths
$cartridge_root = '/usr/libexec/stickshift/cartridges'
$controller_config_path = "ss-app-create"
$controller_config_format = "#{$controller_config_path} -c '%s' --with-namespace '%s' --named '%s'"
$controller_deconfig_path = "ss-app-destroy"
$controller_deconfig_format = "#{$controller_deconfig_path} -c '%s'"
$home_root = "/var/lib/stickshift"

# --------------------------------------------------------------------------
# Account Checks
# --------------------------------------------------------------------------
# These must run after server_steps.rb: I create a <name> app for <framework>

# These depend on test data of this form:
#    And the following test data
#      | accountname 
#      | 00112233445566778899aabbccdde000


# copied from server-common/openshift/user.rb 20110630
def gen_small_uuid()
    # Put config option for rhlogin here so we can ignore uuid for dev environments
    %x[/usr/bin/uuidgen].gsub('-', '').strip
end

Given /^a new gear with namespace "([^\"]*)" and app name "([^\"]*)"$/ do |namespace, name|
  # generate a random account name and use the stock SSH keys
  # generate a random UUID and use the stock keys
  acctname = gen_small_uuid
  @account = {
    'accountname' => acctname,
  }

  command = $controller_config_format % [acctname, namespace, name]
  run command

  # get and store the account UID's by name
  @account['uid'] = Etc.getpwnam(acctname).uid
end

Given /^a new guest account$/ do
  # generate a random account name and use the stock SSH keys
  # generate a random UUID and use the stock keys
  acctname = gen_small_uuid
  @account = {
    'accountname' => acctname,
  }

  command = $controller_config_format % [acctname, '', '']
  run command

  # get and store the account UID's by name
  @account['uid'] = Etc.getpwnam(acctname).uid
end

Given /^the guest account has no application installed$/ do
  # Assume this is true
end

When /^I create a guest account$/ do
  # call /usr/libexec/stickshift/cartridges  @table.hashes.each do |row|
  # generate a random account name and use the stock SSH keys
  # generate a random UUID and use the stock keys
  acctname = gen_small_uuid
  @account = {
      'accountname' => acctname,
    }

  command = $controller_config_format % [acctname, '', '']
  run command

  # get and store the account UID's by name
  @account['uid'] = Etc.getpwnam(acctname).uid
end

When /^I delete the guest account$/ do
  # call /usr/libexec/stickshift/cartridges  @table.hashes.each do |row|
  
  command = $controller_deconfig_format % [@account['accountname']]
  run command

end

When /^I create a new namespace$/ do
  ec = run("#{$rhc_domain_script} create -n vuvuzuzufukuns -l vuvuzuzufuku -p fakepw -d")
end

When /^I delete the namespace$/ do
  ec = run("#{$rhc_domain_script} destroy -n vuvuzuzufukuns -l vuvuzuzufuku -p fakepw -d")
  # FIXME: Need to fix this test to work w/ mongo -- need unique name per run.
  #ec.should be == 0
end

Then /^a namespace should get deleted$/ do
  ec = run("host vuvuzuzufukuns.dev.rhcloud.com | grep \"not found\"")
  #ec.should be == 0
end

Then /^an account password entry should( not)? exist$/ do |negate|
  # use @app['uuid'] for account name
  
  begin
    @pwent = Etc.getpwnam @account['accountname']
  rescue
    nil
  end

  if negate
    @pwent.should be_nil      
  else
    @pwent.should_not be_nil
  end
end

Then /^an HTTP proxy config file should( not)? exist$/ do |negate|

end

Then /^an account home directory should( not)? exist$/ do |negate|
  @homedir = File.directory? "#{$home_root}/#{@account['accountname']}"
    
  if negate
    @homedir.should_not be_true
  else
    @homedir.should be_true
  end
end