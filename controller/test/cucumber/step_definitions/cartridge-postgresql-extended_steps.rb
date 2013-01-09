When /^I select from the postgresql database using the socket file$/ do
  cmd = ssh_command("-o LogLevel=quiet \"PGPASSWORD=\\$OPENSHIFT_POSTGRESQL_DB_PASSWORD /usr/bin/psql -U admin -h \\$OPENSHIFT_POSTGRESQL_DB_SOCKET -d #{@app.name} -c 'select 1' -t\"")

  $logger.debug "Running #{cmd}"

  output = `#{cmd}`
  @postgresql_query_result = output.strip

  $logger.debug "Output: #{output}"
end

Then /^the select result from the postgresql database should be valid$/ do
  @postgresql_query_result.should be == "1"
end