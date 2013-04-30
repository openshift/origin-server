Then /^running (.+) should yield (.+) with a (\d) exitstatus$/ do |script, output, exitstatus|
  @acceptance_output = `#{script} 2>&1`.chomp
  assert_match /#{output}/, @acceptance_output
  assert_equal exitstatus.to_i, $?.exitstatus
end

Then /^no stack traces should have occurred$/ do
  # The #1 leading cause of death for our acceptance scripts is when libraries
  # fail to load.  OpenShift Origin and Enterprise run the same code but
  # sometimes their runtime environment is slightly different.
  #
  # We want to match something like this:
  # "from /opt/rh/ruby193/root/usr/share/ruby/cgi.rb:13:in"
  assert_no_match /(\s+)from .*:\d+:in/, @acceptance_output
end
