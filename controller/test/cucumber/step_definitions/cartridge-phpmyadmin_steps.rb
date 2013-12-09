Given /^a mock application, verify addition and removal of v2 phpmyadmin-([\d\.]+)$/ do |phpmyadmin_version|
  steps %Q{
    Given a new mock-0.1 type application

    When I embed a mysql-5.5 cartridge into the application
    And I embed a phpmyadmin-#{phpmyadmin_version} cartridge into the application
    Then a httpd process will be running
    And the phpmyadmin-#{phpmyadmin_version} cartridge instance directory will exist

    When I stop the phpmyadmin-#{phpmyadmin_version} cartridge
    Then a httpd process will not be running

    When I start the phpmyadmin-#{phpmyadmin_version} cartridge
    Then a httpd process will be running

    When I restart the phpmyadmin-#{phpmyadmin_version} cartridge
    Then a httpd process will be running

    When I destroy the application
    Then a httpd process will not be running
  }
end
