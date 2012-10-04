Given /^an accepted node$/ do
  # TODO: Add any required checks here
end

Given /^the libra client tools$/ do
  File.exists?($create_app_script).should be_true
  File.exists?($create_domain_script).should be_true
  File.exists?($client_config).should be_true
  File.exists?($ctl_app_script).should be_true

  File.exists?($rhc_app_script).should be_true
  File.exists?($rhc_domain_script).should be_true
  File.exists?($rhc_sshkey_script).should be_true
end