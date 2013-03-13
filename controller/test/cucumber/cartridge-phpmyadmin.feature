#@runtime_other4
@runtime
@runtime4
@not-enterprise
Feature: phpMyAdmin Embedded Cartridge

  Scenario Outline: Add Remove phpMyAdmin to one application
    Given a new <php_version> type application
    
    When I embed a mysql-5.1 cartridge into the application
    And I embed a <phpmyadmin_version> cartridge into the application
    Then the http proxy /phpmyadmin will exist
    And 4 processes named httpd will be running
    And the embedded <phpmyadmin_version> cartridge directory will exist
    And the embedded <phpmyadmin_version> cartridge log files will exist

    When I stop the <phpmyadmin_version> cartridge
    Then 2 processes named httpd will be running
    And the web console for the <phpmyadmin_version> cartridge is not accessible

    When I start the <phpmyadmin_version> cartridge
    Then 4 processes named httpd will be running
    And the web console for the <phpmyadmin_version> cartridge is accessible
    
    When I restart the <phpmyadmin_version> cartridge
    Then 4 processes named httpd will be running
    And the web console for the <phpmyadmin_version> cartridge is accessible

    When I destroy the application
    Then 0 processes named httpd will be running
    And the http proxy /phpmyadmin will not exist
    And the embedded <phpmyadmin_version> cartridge directory will not exist
    And the embedded <phpmyadmin_version> cartridge log files will not exist
    
    @rhel-only
    Scenarios: RHEL scenarios
      | php_version | phpmyadmin_version |
      | php-5.3     | phpmyadmin-3.4     |

    @fedora-only
    Scenarios: Fedora 18 scenarios
      | php_version | phpmyadmin_version |
      | php-5.4     | phpmyadmin-3.5     |
