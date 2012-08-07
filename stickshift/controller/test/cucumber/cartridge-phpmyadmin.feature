@runtime
@runtime4
Feature: phpMyAdmin Embedded Cartridge

  Scenario: Add Remove phpMyAdmin to one application
    Given a new perl-5.10 type application
    
    When I embed a mysql-5.1 cartridge into the application
    And I embed a phpmyadmin-3.4 cartridge into the application
    Then the embedded phpmyadmin-3.4 cartridge http proxy file will exist
    And 4 processes named httpd will be running
    And the embedded phpmyadmin-3.4 cartridge directory will exist
    And the embedded phpmyadmin-3.4 cartridge log files will exist
    And the embedded phpmyadmin-3.4 cartridge control script named phpmyadmin will exist

    When I stop the phpmyadmin-3.4 cartridge
    Then 2 processes named httpd will be running

    When I start the phpmyadmin-3.4 cartridge
    Then 4 processes named httpd will be running
    And the phpmyadmin web console url will be accessible
    
    When I restart the phpmyadmin-3.4 cartridge
    Then 4 processes named httpd will be running
    And the phpmyadmin web console url will be accessible

    When I destroy the application
    Then 0 processes named httpd will be running
    And the embedded phpmyadmin-3.4 cartridge http proxy file will not exist
    And the embedded phpmyadmin-3.4 cartridge directory will not exist
    And the embedded phpmyadmin-3.4 cartridge log files will not exist
    And the embedded phpmyadmin-3.4 cartridge control script named phpmyadmin will not exist
