require 'fileutils'

Given /^cron is (running|stopped)$/ do | status |
  cron_cart = @gear.carts['cron-1.4']

  cron_user_root = "#{$home_root}/#{@gear.uuid}/#{cron_cart.name}"
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
    assert_file_exists jobs_enabled_file
  else
    assert_file_not_exists jobs_enabled_file
  end
end

Then /^cron jobs will( not)? be enabled$/ do | negate |
  cron_cart = @gear.carts['cron-1.4']

  cron_user_root = "#{$home_root}/#{@gear.uuid}/#{cron_cart.name}"
  jobs_enabled_file = "#{cron_user_root}/run/jobs.enabled"

  $logger.info("Checking for cron jobs marker at #{jobs_enabled_file}")
  if negate
    assert_file_not_exists jobs_enabled_file
  else
    assert_file_exists jobs_enabled_file
  end
end
