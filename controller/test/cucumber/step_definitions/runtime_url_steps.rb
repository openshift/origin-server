Then /^the web console for the metrics\-([\d\.]+) cartridge is( not)? accessible$/ do |version, negate|
  steps %Q{
    Then the web console for the metrics-#{version} cartridge at /metrics/read.php is#{negate} accessible
  }
end

Then /^the web console for the rockmongo\-([\d\.]+) cartridge is( not)? accessible$/ do |version, negate|
  steps %Q{
    Then the web console for the rockmongo-#{version} cartridge at /rockmongo/js/collection.js is#{negate} accessible
  }
end

Then /^the web console for the phpmyadmin\-([\d\.]+) cartridge is( not)? accessible$/ do |version, negate|
  steps %Q{
    Then the web console for the phpmyadmin-#{version} cartridge at /phpmyadmin/js/sql.js is#{negate} accessible
  }
end

When /^I run the health\-check for the ([^ ]+) cartridge$/ do | type |

  host = "#{@app.name}-#{current_app_namespace}.#{$cloud_domain}"

  # Use curl to hit the app, causing restorer to turn it back on.
  command = "/usr/bin/curl -k -H 'Host: #{host}' -s http://localhost/health"
  output = run_stdout command
  output.chomp!

  OpenShift::timeout(60) do
    while output != '1'
      output = run_stdout command
      output.chomp!
      $logger.info("Idler waiting for httpd graceful to finish. #{host}")
      sleep 1
    end
  end

  output.should == '1'
end
