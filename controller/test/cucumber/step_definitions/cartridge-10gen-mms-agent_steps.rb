require 'fileutils'

Given /^an agent settings.py file is created$/ do
  filepath = "/var/lib/openshift/#{@gear.uuid}/app-root/repo/.openshift/mms/settings.py"

  system("mkdir -p /var/lib/openshift/#{@gear.uuid}/app-root/repo/.openshift/mms > /dev/null")
  system("cp /usr/local/share/mms-agent/settings.py #{filepath} > /dev/null")
  system("chown -R #{@gear.container.uid}:#{@gear.container.gid} /var/lib/openshift/#{@gear.uuid}/app-root/repo/.openshift/mms/")

  assert_file_exist filepath
end
