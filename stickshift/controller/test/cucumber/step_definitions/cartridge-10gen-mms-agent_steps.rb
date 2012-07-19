require 'fileutils'

$mms_agent_version = "0.1"
$mms_agent_cart_root = "/usr/libexec/stickshift/cartridges/embedded/10gen-mms-agent-#{$mms_agent_version}"
$mms_agent_hooks = $mms_agent_cart_root + "/info/hooks"
$mms_agent_config = $mms_agent_hooks + "/configure"
$mms_agent_config_format = "#{$mms_agent_config} %s %s %s"
$mms_agent_deconfig = $mms_agent_hooks + "/deconfigure"
$mms_agent_deconfig_format = "#{$mms_agent_deconfig} %s %s %s"

Given /^an agent settings.py file is created$/ do
  system("mkdir -p /var/lib/stickshift/#{@gear.uuid}/app-root/repo/.openshift/mms > /dev/null")
  system("cp /usr/local/share/mms-agent/settings.py /var/lib/stickshift/#{@gear.uuid}/app-root/repo/.openshift/mms/settings.py > /dev/null")
  system("chown -R #{@gear.container.user.uid}:#{@gear.container.user.uid} /var/lib/stickshift/#{@gear.uuid}/app-root/repo/.openshift/mms/")

  filepath = "/var/lib/stickshift/#{@gear.uuid}/app-root/repo/.openshift/mms/settings.py"
  settingsfile = File.new filepath
  settingsfile.should be_a(File)
end
