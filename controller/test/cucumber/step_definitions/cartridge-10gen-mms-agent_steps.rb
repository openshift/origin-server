require 'fileutils'

Given /^a ([^ ]+) application, verify addition and removal of 10gen-mms-agent$/ do |cart_name|
  steps %Q{
    Given a new #{cart_name} type application
    And I embed a mongodb-2.2 cartridge into the application
    And an agent settings.py file is created
    And I embed a 10gen-mms-agent-0.1 cartridge into the application

    Then 1 process named python will be running
    And the embedded 10gen-mms-agent-0.1 cartridge subdirectory named mms-agent will exist
    And the embedded 10gen-mms-agent-0.1 cartridge log files will exist
    And the embedded 10gen-mms-agent-0.1 cartridge control script will not exist

    When I stop the 10gen-mms-agent-0.1 cartridge
    Then 0 processes named python will be running

    When I start the 10gen-mms-agent-0.1 cartridge
    Then 1 processes named python will be running

    When I restart the 10gen-mms-agent-0.1 cartridge
    Then 1 processes named python will be running

    When I destroy the application
    Then 0 processes named python will be running
    And the embedded 10gen-mms-agent-0.1 cartridge subdirectory named mms-agent will not exist
    And the embedded 10gen-mms-agent-0.1 cartridge log files will not exist
  }
end

Given /^an agent settings.py file is created$/ do
  filepath = "/var/lib/openshift/#{@gear.uuid}/app-root/repo/.openshift/mms/settings.py"

  system("mkdir -p /var/lib/openshift/#{@gear.uuid}/app-root/repo/.openshift/mms > /dev/null")
  system("cp /usr/local/share/mms-agent/settings.py #{filepath} > /dev/null")
  system("chown -R #{@gear.container.user.uid}:#{@gear.container.user.uid} /var/lib/openshift/#{@gear.uuid}/app-root/repo/.openshift/mms/")

  assert_file_exists filepath
end
