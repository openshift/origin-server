When /^I select from the postgresql database using the socket file$/ do
  cmd = ssh_command("-o LogLevel=quiet \"export PGPASSWORD=\\$OPENSHIFT_POSTGRESQL_DB_PASSWORD; echo 'select 1; \\q' | /usr/bin/psql -U admin -h \\$OPENSHIFT_POSTGRESQL_DB_SOCKET -d #{@app.name} -t\"")

  $logger.debug "Running #{cmd}"

  output = `#{cmd}`
  @postgresql_query_result = output.strip

  $logger.debug "Output: #{output}"
end

Then /^the select result from the postgresql database should be valid$/ do
  @postgresql_query_result.should be == "1"
end