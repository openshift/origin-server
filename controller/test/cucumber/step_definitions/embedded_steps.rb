Given /^the libra client tools, create a new php-([^ ]+) application, verify addition and removal of mysql-5.5 , phpmyadmin-([^ ]+) , cron-1.4 , mongodb-2.4$/ do |php_version, phpmyadmin_version|
  steps %{
    Given the libra client tools
    When 1 php-#{php_version} applications are created
    Then the applications should be accessible

    Given an existing php-#{php_version} application without an embedded cartridge
    When the embedded mysql-5.5 cartridge is added
    And the embedded phpmyadmin-#{phpmyadmin_version} cartridge is added
    Then the application should be accessible
    When the application uses mysql
    Then the application should be accessible
    And the mysql response is successful
    When the embedded phpmyadmin-#{phpmyadmin_version} cartridge is removed
    And the embedded mysql-5.5 cartridge is removed
    Then the application should be accessible

    When the embedded mongodb-2.4 cartridge is added
    And the embedded cron-1.4 cartridge is added
    Then the application should be accessible
    And the embedded mongodb-2.4 cartridge is removed
    And the embedded cron-1.4 cartridge is removed
    Then the application should be accessible

    When the application is destroyed
    Then the application should not be accessible
  }
end
