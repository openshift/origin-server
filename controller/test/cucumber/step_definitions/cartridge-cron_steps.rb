require 'fileutils'

Given /^a ([^ ]+) application, verify addition and removal of cron$/ do |cart_name|
  steps %Q{
    Given a new #{cart_name} type application
    And I embed a cron-1.4 cartridge into the application
    And cron is running

    Then the embedded cron-1.4 cartridge directory will exist
    And the embedded cron-1.4 cartridge subdirectory named log will exist
    And the embedded cron-1.4 cartridge subdirectory named run will exist
    And cron jobs will be enabled

    When I stop the cron-1.4 cartridge
    Then cron jobs will not be enabled
    And cron is stopped

    When I start the cron-1.4 cartridge
    Then cron jobs will be enabled
    And cron is running

    When I restart the cron-1.4 cartridge
    Then cron jobs will be enabled

    When I destroy the application
    Then cron is stopped
    And the embedded cron-1.4 cartridge directory will not exist
    And the embedded cron-1.4 cartridge subdirectory named log will not exist
    And the embedded cron-1.4 cartridge control script will not exist
    And the embedded cron-1.4 cartridge subdirectory named run will not exist
  }
end

Given /^cron is (running|stopped)$/ do | status |
  cron_cart = @gear.carts['cron-1.4']

  cron_user_root = "#{$home_root}/#{@gear.uuid}/#{cron_cart.directory}"
  jobs_enabled_file = "#{cron_user_root}/run/jobs.enabled"

  mark_exists = File.exists? jobs_enabled_file
  $logger.info("Checking for cron jobs marker file at #{jobs_enabled_file}: #{mark_exists}")

  if 'running' == status
    if not mark_exists
      cron_cart.start
    end
    exit_test = lambda {|f| ! File.exists? f}
  else
    if mark_exists
      cron_cart.stop
    end
    exit_test = lambda {|f| File.exists? f}
  end

  $logger.info("Checking for cron jobs marker file at #{jobs_enabled_file}")
  OpenShift::timeout(30) do
    while exit_test.call(jobs_enabled_file)
      sleep 1
      $logger.info("Waiting for marker file to exist at #{marker_file}")
    end
  end

  if 'running' == status
    assert_file_exist jobs_enabled_file
  else
    refute_file_exist jobs_enabled_file
  end
end

Then /^cron jobs will( not)? be enabled$/ do | negate |
  cron_cart = @gear.carts['cron-1.4']

  cron_user_root = "#{$home_root}/#{@gear.uuid}/#{cron_cart.directory}"
  jobs_enabled_file = "#{cron_user_root}/run/jobs.enabled"

  $logger.info("Checking for cron jobs marker at #{jobs_enabled_file}")
  if negate
    refute_file_exist jobs_enabled_file
  else
    assert_file_exist jobs_enabled_file
  end
end
