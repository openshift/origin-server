When /^I select from the mysql database using the socket file$/ do
  cmd = ssh_command("-o LogLevel=quiet \"/usr/bin/mysql -S \\$OPENSHIFT_MYSQL_DB_SOCKET -u \\$OPENSHIFT_MYSQL_DB_USERNAME --password=\\$OPENSHIFT_MYSQL_DB_PASSWORD --batch --silent --execute='select 1'\"") 

  $logger.debug "Running #{cmd}"

  output = `#{cmd}`
  @mysql_query_result = output.strip

  $logger.debug "Output: #{output}"
end

Then /^the select result from the mysql database should be valid$/ do
  @mysql_query_result.should be == "1"
end