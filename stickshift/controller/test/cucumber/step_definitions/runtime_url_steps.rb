Then /^the web console for the metrics\-([\d\.]+) cartridge is( not)? accessible$/ do |version, negate|
  steps %Q{
    Then the web console for the metrics-#{version} cartridge at /read.php is#{negate} accessible
  }
end

Then /^the web console for the rockmongo\-([\d\.]+) cartridge is( not)? accessible$/ do |version, negate|
  steps %Q{
    Then the web console for the rockmongo-#{version} cartridge at /js/collection.js is#{negate} accessible
  }
end

Then /^the web console for the phpmyadmin\-([\d\.]+) cartridge is( not)? accessible$/ do |version, negate|
  steps %Q{
    Then the web console for the phpmyadmin-#{version} cartridge at /js/sql.js is#{negate} accessible
  }
end

Then /^the web console for the phpmoadmin\-([\d\.]+) cartridge is( not)? accessible$/ do |version, negate|
  steps %Q{
    Then the web console for the phpmoadmin-#{version} cartridge at / is#{negate} accessible
  }
end

When /^I run the health\-check for the ([^ ]+) cartridge$/ do | type |
  host = "#{@app.name}-#{@account.domain}.dev.rhcloud.com"

  url = case type
    when 'perl-5.10'
      "health_check.pl"
    when 'php-5.3'
      "health_check.php"
    else
      "health"
  end

  # Use curl to hit the app, causing restorer to turn it back
  # on and redirect.  Curl then follows that redirect.
  command = "/usr/bin/curl -L -k -H 'Host: #{host}' -s http://localhost/#{url}"
  output = run_stdout command
  output.chomp!

  StickShift::timeout(60) do
    while output != '1'
      output = run_stdout command
      output.chomp!
      $logger.info("Idler waiting for httpd graceful to finish. #{host}")
      sleep 1
    end
  end

  output.should == '1'
end