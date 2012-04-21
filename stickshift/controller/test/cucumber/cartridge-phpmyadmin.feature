@internals
@node
Feature: phpMyAdmin Embedded Cartridge

  Scenario Outline: Add Remove phpMyAdmin to one application
    Given an accepted node
    And a new guest account
    And a new <type> application
    And a new mysql database
    When I configure phpmyadmin
    Then a phpmyadmin http proxy file will exist
    And a phpmyadmin httpd will be running
    And the phpmyadmin directory will exist
    And phpmyadmin log files will exist
    And the phpmyadmin control script will exist

    When I stop phpmyadmin
    Then a phpmyadmin httpd will not be running
    And phpmyadmin is stopped
    When I start phpmyadmin
    Then a phpmyadmin httpd will be running
    When I restart phpmyadmin
    Then a phpmyadmin httpd will be running

    When I deconfigure phpmyadmin
    Then a phpmyadmin http proxy file will not exist
    And a phpmyadmin httpd will not be running
    And the phpmyadmin directory will not exist
    And phpmyadmin log files will not exist
    And the phpmyadmin control script will not exist

  Scenarios: Add Remove phpMyAdmin to one Application Scenarios
    |type|
    |php|
