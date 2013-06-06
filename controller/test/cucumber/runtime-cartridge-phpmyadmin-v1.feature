@runtime
@runtime_extended_other3
@not-enterprise
@not-fedora-19
Feature: phpMyAdmin Embedded Cartridge

  @runtime_extended_other3
  @rhel-only
  Scenario: Add Remove phpMyAdmin to one application
    #Given a php-5.3 application, verify addition and removal of phpmyadmin-3.4
    Given a new php-5.3 type application

    When I embed a mysql-5.1 cartridge into the application
    And I embed a phpmyadmin-3.4 cartridge into the application
    Then the http proxy /phpmyadmin will exist
    And 4 processes named httpd will be running
    And the embedded phpmyadmin-3.4 cartridge directory will exist
    And the embedded phpmyadmin-3.4 cartridge log files will exist

    When I stop the phpmyadmin-3.4 cartridge
    Then 2 processes named httpd will be running
    And the web console for the phpmyadmin-3.4 cartridge is not accessible

    When I start the phpmyadmin-3.4 cartridge
    Then 4 processes named httpd will be running
    And the web console for the phpmyadmin-3.4 cartridge is accessible

    When I restart the phpmyadmin-3.4 cartridge
    Then 4 processes named httpd will be running
    And the web console for the phpmyadmin-3.4 cartridge is accessible

    When I destroy the application
    Then 0 processes named httpd will be running
    And the http proxy /phpmyadmin will not exist
    And the embedded phpmyadmin-3.4 cartridge directory will not exist
    And the embedded phpmyadmin-3.4 cartridge log files will not exist
