@broker_api
@broker_api1
Feature: applications
  As an API client
  In order to do things with domains
  I want to List, Create, Retrieve, Start, Stop, Restart, Force-stop and Delete applications

  Scenario Outline: Create, Get, Resolve DNS, List, Delete application
    #Given a new user, create a ruby-<ruby_version> application using <format> format and verify application creation API
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=ruby-<ruby_version>"
    Then the response should be "201"
    And the response should be a "application" with attributes "name=app&framework=ruby-<ruby_version>"
    When I send a GET request to "/domains/api<random>/applications/app"
    Then the response should be "200"
    And the response should be a "application" with attributes "name=app&framework=ruby-<ruby_version>"
    When I send a GET request to "/domains/api<random>/applications/app/dns_resolvable"
    Then the response should be one of "200,404"
    When I send a GET request to "/domains/api<random>/applications"
    Then the response should be "200"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=start"
    Then the response should be "200"
    When I send a GET request to "/domains/api<random>/applications/app/gear_groups"
    Then the response should be a "gear-group/gears/gear" with attributes "state=started"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=stop"
    Then the response should be "200"
    When I send a GET request to "/domains/api<random>/applications/app/gear_groups"
    Then the response should be a "gear-group/gears/gear" with attributes "state=stopped"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=restart"
    Then the response should be "200"
    When I send a GET request to "/domains/api<random>/applications/app/gear_groups"
    Then the response should be a "gear-group/gears/gear" with attributes "state=started"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=thread-dump"
    Then the response should be "200"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=force-stop"
    Then the response should be "200"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=ruby-<ruby_version>"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=100"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=scale-up"
    Then the response should be "422"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=scale-down"
    Then the response should be "422"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "200"
    When I send a GET request to "/domains/api<random>/applications/app"
    Then the response should be "404"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=101"

    Scenarios: Cartridge Versions
      | format | ruby_version |
      | JSON   |      1.9     |
      | XML    |      1.9     |


  Scenario Outline: Create application with multiple cartridges and test the embedded cartridge
    #Given a new user, create a php-<php_version> application with phpmyadmin-<phpmyadmin_version> using <format> format and verify application creation API
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridges=php-<php_version>&cartridges=<database>&cartridges=phpmyadmin-<phpmyadmin_version>&initial_git_url=https://github.com/openshift/wordpress-example"
    Then the response should be "201"
    And the response should be a "application" with attributes "name=app&framework=php-<php_version>"
    When I send a POST request to "/domains/api<random>/applications/app/cartridges/<database>/events" with the following:"event=stop"
    Then the response should be "200"
    When I send a POST request to "/domains/api<random>/applications/app/cartridges/<database>/events" with the following:"event=start"
    Then the response should be "200"
    When I send a POST request to "/domains/api<random>/applications/app/cartridges/<database>/events" with the following:"event=restart"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app/cartridges/<database>"
    Then the response should be "200"
    When I send a GET request to "/domains/api<random>/applications/app/descriptor"
    Then the response descriptor should have "php-<php_version>,phpmyadmin-<phpmyadmin_version>" as dependencies
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "200"

    Scenarios: Cartridge Versions
      | format | php_version | phpmyadmin_version | database  |
      | JSON   |     5.3     |        4           | mysql-5.1 |
      | XML    |     5.3     |        4           | mysql-5.1 |

  Scenario Outline: Create application with invalid cartridge combinations and invalid names
    #Given a new user, create an invalid application with php-<php_version>, ruby-1.9, mysql-5.1, phpmyadmin-<phpmyadmin_version> using <format> format and verify application creation API
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridges=<database>&cartridges=phpmyadmin-<phpmyadmin_version>"
    Then the response should be "422"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridges=php-<php_version>&cartridges=ruby-<ruby_version>"
    Then the response should be "422"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=bogus"
    Then the response should be "422"
    And the error message should have "field=cartridge&severity=error&exit_code=109"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge="
    Then the response should be "422"
    And the error message should have "field=cartridge&severity=error&exit_code=109"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app"
    Then the response should be "422"
    And the error message should have "field=cartridge&severity=error&exit_code=109"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=&cartridge=php-<php_version>"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=105"
    When I send a POST request to "/domains/api<random>/applications" with the following:"cartridge=php-<php_version>"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=105"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app?one&cartridge=php-<php_version>"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=105"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=appone1234567890123456789012345678901234567890&cartridge=php-<php_version>"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=105"

    Scenarios: Cartridge Versions
      | format | php_version | phpmyadmin_version | database  | ruby_version |
      | JSON   |     5.3     |        4           | mysql-5.1 |      1.9     |
      | XML    |     5.3     |        4           | mysql-5.1 |      1.9     |