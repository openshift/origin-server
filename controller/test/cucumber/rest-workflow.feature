@broker
Feature: Rest Quick tests
  As an developer I want to make sure I didn't break anything that is going to prevent others from working
  
  Scenario Outline: Typical Workflow
    #Given a new user, verify typical REST interactios with a <php_version> application over <format> format
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-rsa&content=XYZ123567"
    Then the response should be "201"
    And the response should be a "key" with attributes "name=api&type=ssh-rsa&content=XYZ123567"
    When I send a GET request to "/user/keys/api"
    Then the response should be "200"
    And the response should be a "key" with attributes "name=api&type=ssh-rsa&content=XYZ123567"
    When I send a POST request to "/domains" with the following:"name=api<random>"
    Then the response should be "201"
    When I send a POST request to "/domains/api<random>/applications" with the following:"name=app&cartridge=<cart_name>"
    Then the response should be "201"
    And the response should be a "application" with attributes "name=app&framework=<cart_name>"
    When I send a GET request to "/domains/api<random>/applications/app"
    Then the response should be "200"
    And the response should be a "application" with attributes "name=app&framework=<cart_name>"
    When I send a GET request to "/domains/api<random>/applications"
    Then the response should be "200"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=stop"
    Then the response should be "200"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=start"
    Then the response should be "200"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=start"
    Then the response should be "200"
    When I send a POST request to "/domains/api<random>/applications/app/events" with the following:"event=force-stop"
    Then the response should be "200"
    When I send a POST request to "/domains/api<random>/applications/app/aliases" with the following:"id=app-api<random>.foobar.com"
    Then the response should be "201"
    When I send a DELETE request to "/domains/api<random>/applications/app/aliases/app-api<random>.foobar.com"
    Then the response should be "200"
    When I send a POST request to "/domains/api<random>/applications/app/cartridges" with the following:"cartridge=<db_cart_name>"
    Then the response should be "201"
    When I send a GET request to "/domains/api<random>/applications/app/descriptor"
    Then the response descriptor should have "<cart_name>,<db_cart_name>" as dependencies
    When I send a POST request to "/domains/api<random>/applications/app/cartridges/<db_cart_name>/events" with the following:"event=stop"
    Then the response should be "200"
    When I send a POST request to "/domains/api<random>/applications/app/cartridges/<db_cart_name>/events" with the following:"event=start"
    Then the response should be "200"
    When I send a POST request to "/domains/api<random>/applications/app/cartridges/<db_cart_name>/events" with the following:"event=restart"
    Then the response should be "200"
    When I send a DELETE request to "/domains/api<random>/applications/app/cartridges/<db_cart_name>"
    Then the response should be "200"
    When I send a PUT request to "/domains/api<random>" with the following:"name=apix<random>"
    Then the response should be "422"
    When I send a DELETE request to "/domains/api<random>/applications/app"
    Then the response should be "200"
    When I send a PUT request to "/domains/api<random>" with the following:"name=apix<random>"
    Then the response should be "200"
    And the response should be a "domain" with attributes "name=apix<random>"
    When I send a GET request to "/domains/apix<random>/applications/app"
    Then the response should be "404"
    When I send a DELETE request to "/domains/apix<random>"
    Then the response should be "200"
    When I send a DELETE request to "/user/keys/api"
    Then the response should be "200"

    @rhel-only
    Scenarios: RHEL
      | format | cart_name | db_cart_name |
      | JSON   |  php-5.3  |  mysql-5.1   |
      | JSON   |  php-5.4  |  mysql-5.1   |
      | XML    |  php-5.3  |  mysql-5.1   |
      | XML    |  php-5.4  |  mysql-5.1   |

    @fedora-19-only
    Scenarios: Fedora 19
      | format | cart_name | db_cart_name   |
      | JSON   |  php-5.5  |  mariadb-5.5   |
      | XML    |  php-5.5  |  mariadb-5.5   |
