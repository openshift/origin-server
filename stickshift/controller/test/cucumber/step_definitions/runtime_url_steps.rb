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
