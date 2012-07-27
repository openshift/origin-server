require 'fileutils'

Given /^cron is (running|stopped)$/ do | status |
  action = status == "running" ? "start" : "stop"

  cron_cart = @gear.carts['cron-1.4']

  cron_user_root = "#{$home_root}/#{@gear.uuid}/#{cron_cart.name}"
  jobs_enabled_file = "#{cron_user_root}/run/jobs.enabled"

  $logger.info("Checking for cron jobs marker file at #{jobs_enabled_file}")
  begin
    marker_file = File.new jobs_enabled_file
  rescue Errno::ENOENT
    marker_file = nil
  end

  outbuf = []

  case action
  when 'start'
    if marker_file.nil?
      cron_cart.start
    end
    exit_test = lambda { |marker| marker.is_a? File }
  when 'stop'
    if marker_file.is_a? File
      cron_cart.stop
    end
    exit_test = lambda { |marker| marker == nil }
  # else
  #   raise an exception
  end

  # now loop until it's true
  max_tries = 10
  poll_rate = 3
  tries = 0

  $logger.info("Checking for cron jobs marker file at #{jobs_enabled_file}")
  begin
    marker_file = File.new jobs_enabled_file
  rescue Errno::ENOENT
    marker_file = nil
  end

  while (not exit_test.call(marker_file) and tries < max_tries)
    tries += 1

    $logger.info("Waiting #{poll_rate}s for marker file to exist at #{marker_file} (retry #{tries} of #{max_tries})")

    sleep poll_rate
    begin
      marker_file = File.new jobs_enabled_file
    rescue Errno::ENOENT
      marker_file = nil
    end
  end
end

Then /^cron jobs will( not)? be enabled$/ do | negate |
  cron_cart = @gear.carts['cron-1.4']

  cron_user_root = "#{$home_root}/#{@gear.uuid}/#{cron_cart.name}"
  jobs_enabled_file = "#{cron_user_root}/run/jobs.enabled"

  $logger.info("Checking for cron jobs marker at #{jobs_enabled_file}")
  begin
    marker_file = File.new jobs_enabled_file
  rescue Errno::ENOENT
    marker_file = nil
  end

  unless negate
    marker_file.should be_a(File)
  else
    marker_file.should be_nil
  end
end