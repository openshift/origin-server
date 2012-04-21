# 
# 
# Steps that can be used to check applications installed on a server (node)
#
#require 'etc'


When /^I create a new namespace OLD$/ do
  exit_code = run("#{$create_domain_script} -n vuvuzuzufukuns -l vuvuzuzufuku -p fakepw -d")
end

When /^I make the REST call to delete the namespace$/ do
  ec = run("curl -k --data-urlencode \"json_data=#{"{\\\"rhlogin\\\":\\\"vuvuzuzufuku\\\",\\\"delete\\\":true,\\\"namespace\\\":\\\"vuvuzuzufukuns\\\"}"}\" -d \"password=' '\" https://localhost/broker/domain")
  ec.should be == 0
end