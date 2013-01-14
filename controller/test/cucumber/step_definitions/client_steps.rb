Given /^an accepted node$/ do
  # TODO: Add any required checks here
end

Given /^the libra client tools$/ do
  File.exists?($client_config).should be_true
  File.exists?($rhc_script).should be_true
end
