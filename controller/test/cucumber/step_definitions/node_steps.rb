# 
# 
# Steps that can be used to check applications installed on a server (node)
#
#require 'etc'

require 'open4'
require 'dnsruby'

# Controller cartridge command paths
$cartridge_root = '/usr/libexec/openshift/cartridges'
$controller_config_path = "oo-app-create"
$controller_config_format = "#{$controller_config_path} -c '%s' -a '%s' --with-namespace '%s' --with-app-name '%s'"
$controller_deconfig_path = "oo-app-destroy"
$controller_deconfig_format = "#{$controller_deconfig_path} -c '%s' -a '%s' --with-namespace '%s' --with-app-name '%s'"
$home_root = "/var/lib/openshift"

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

def gen_unique_login_and_namespace(namespace=nil)
  if !namespace
    chars = ("1".."9").to_a
    namespace = "ci" + Array.new(8, '').collect{chars[rand(chars.size)]}.join
  end
  login = "cucumber-test_#{namespace}@example.com"
  [ login, namespace ]
end

def gen_unique_app_name
  chars = ("1".."9").to_a
  "app" + Array.new(4, '').collect{chars[rand(chars.size)]}.join
end

Given /^a new gear with namespace "([^\"]*)" and app name "([^\"]*)"$/ do |namespace, name|
  # generate a random account name and use the stock SSH keys
  # generate a random UUID and use the stock keys
  acctname = gen_small_uuid
  login, namespace = gen_unique_login_and_namespace(namespace)
  @account = {
    'accountname' => acctname,
    'login' => login,
    'namespace' => namespace,
    'appnames' => [ name ],
  }

  command = $controller_config_format % [acctname, acctname, namespace, name]
  runcon(command, $selinux_user, $selinux_role, $selinux_type)

  # get and store the account UID's by name
  @account['uid'] = Etc.getpwnam(acctname).uid
end

Given /^a new guest account$/ do
  # generate a random account name and use the stock SSH keys
  # generate a random UUID and use the stock keys
  acctname = gen_small_uuid
  login, namespace = gen_unique_login_and_namespace
  appname = gen_unique_app_name
  @account = {
    'accountname' => acctname,
    'login' => login,
    'namespace' => namespace,
    'appnames' => [ appname ],
  }

  command = $controller_config_format % [acctname, acctname, namespace, appname]
  runcon(command, $selinux_user, $selinux_role, $selinux_type)

  # get and store the account UID's by name
  @account['uid'] = Etc.getpwnam(acctname).uid
end

Given /^the guest account has no application installed$/ do
  # Assume this is true
end

When /^I create a guest account$/ do
  # call /usr/libexec/openshift/cartridges  @table.hashes.each do |row|
  # generate a random account name and use the stock SSH keys
  # generate a random UUID and use the stock keys
  acctname = gen_small_uuid
  login, namespace = gen_unique_login_and_namespace
  appname = gen_unique_app_name
  @account = {
    'accountname' => acctname,
    'login' => login,
    'namespace' => namespace,
    'appnames' => [ appname ],
  }

  command = $controller_config_format % [acctname, acctname, namespace, appname]
  runcon(command, $selinux_user, $selinux_role, $selinux_type)

  # get and store the account UID's by name
  @account['uid'] = Etc.getpwnam(acctname).uid
end

When /^I delete the guest account$/ do
  # call /usr/libexec/openshift/cartridges  @table.hashes.each do |row|
  
  command = $controller_deconfig_format % [@account['accountname'],
                                           @account['accountname'],
                                           @account['namespace'],
                                           @account['appnames'][0]]
  runcon(command, $selinux_user, $selinux_role, $selinux_type)

end

When /^I create a new namespace$/ do
  acctname = gen_small_uuid
  login, namespace = gen_unique_login_and_namespace
  @account = {
    'accountname' => acctname,
    'login' => login,
    'password' => 'xyz123',
    'namespace' => namespace
  }
  register_user(login, "xyz123") if $registration_required
  ec = rhc_create_domain(AppHelper::TestApp.new(namespace, login, nil, nil, @account['password'], nil))
  #ec = run("#{$rhc_script} domain create #{namespace} -l #{login} -p #{@account['password']} -d")
end

When /^I create a new namespace called "([^\"]*)"$/ do |namespace_key|
  @unique_namespace_apps_hash ||= {} 
  login, namespace = gen_unique_login_and_namespace
  register_user(login, "xyz123") if $registration_required
  empty_app = AppHelper::TestApp.new(namespace, login, nil, nil, "xyz123", nil)
  rhc_create_domain(empty_app)
  raise "Could not create domain: #{empty_app.create_domain_code}" unless empty_app.create_domain_code == 0
   @unique_namespace_apps_hash[namespace_key] = empty_app 
end
 

When /^I delete the namespace$/ do
#  ec = run("#{$rhc_script} domain destroy #{@account['namespace']} -l #{@account['login']} -p #{@account['password']} -d")
  ec = rhc_delete_domain(AppHelper::TestApp.new(@account['namespace'], @account['login'], nil, nil, @account['password'], nil))
  ec.should be_true
end

Then /^a namespace should get deleted$/ do
  res = Dnsruby::Resolver.new
  begin
    maxttl=300
    minretry=5
    Timeout::timeout(maxttl + 20) do
      while true
        Dnsruby::PacketSender.clear_caches
        ret = res.query("#{@account['namespace']}.#{$cloud_domain}", Dnsruby::Types.TXT)
        if ret.answer.length >= 1
          if ret.answer[0].ttl > maxttl
            retryin = maxttl
          elsif ret.answer[0].ttl < minretry
            retryin = minretry
          else
            retryin = ret.answer[0].ttl
          end
        else
          retryin = maxttl
        end
        $logger.debug "The domain is still resolvable.  Waiting for the TTL to expire in #{retryin} seconds."
        sleep(retryin)
      end
    end
  rescue Timeout::Error
    $logger.warn "Timed out while waiting for the domain name to disappear."
    raise
  rescue Dnsruby::NXDomain
    true
  end
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

And /^the group "([^\"]*)" is added on the node$/ do |group_name|
  output_buffer=[]
  command = "groupadd #{group_name}"
  exit_code = run(command, output_buffer)    
  if !(output_buffer[0].include? ("already exists")) && exit_code !=0
     raise "Cannot add group '#{group_name}' to the node. Running '#{command}' returns exit code: #{exit_code} and output: #{output_buffer[0]}"
  end
end

And /^the group "([^\"]*)" is deleted from the node$/ do |group_name|
  output_buffer=[]
  command = "groupdel #{group_name}"
  exit_code = run(command, output_buffer)
  if !(output_buffer[0].include? ("does not exists")) && exit_code !=0
     raise "Cannot delete group '#{group_name}' from the node. Running '#{command}' returns exit code: #{exit_code} and output: #{output_buffer[0]}"
  end
end

#When more than one group is to be added, separate each group with a comma
#For example: a format for a single group is "foo" and for multiple groups is "foo,group1,group2"
Then /^the groups? "([^\"]*)" is assigned as supplementary groups? to upcoming new gears on the node$/ do |supplementary_group|
   filepath="/etc/openshift/node.conf"
   if File.exists?(filepath)
    file =  File.open(filepath, 'a')
    file.write "GEAR_SUPPLEMENTARY_GROUPS=\"#{supplementary_group}\"\n"
    file.close
   else
     raise "Cannot modify file /etc/openshift/node.conf because file does not exist."
   end
end

And /^I delete the supplementary group setting from \/etc\/openshift\/node.conf$/ do 
  output_buffer=[]
  filepath="/etc/openshift/node.conf"
  command = "sed -i '\/\\(^GEAR_SUPPLEMENTARY_GROUPS=.*\\)\/d' #{filepath}"
  exit_code = run(command, output_buffer)
  if !(output_buffer[0].include? ("does not exists")) && exit_code !=0
     raise "Cannot delete GEAR_SUPPLEMENTARY_GROUPS setting in file '#{filepath}' from the node. Running '#{command}' returns exit code: #{exit_code} and output: #{output_buffer[0]}"
  end
end

