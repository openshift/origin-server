@runtime_extended3
@not-enterprise
Feature: phpMyAdmin Embedded Cartridge

  @rhel-only
  Scenario Outline: Add Remove phpMyAdmin to one application
    #Given a mock application, verify addition and removal of v2 phpmyadmin-3.4
    Given a v2 default node
    Given a new mock-0.1 type application

    When I embed a <database> cartridge into the application
    And I embed a phpmyadmin-<phpmyadmin_version> cartridge into the application
    Then a httpd process will be running
    And the phpmyadmin-<phpmyadmin_version> cartridge instance directory will exist

    When I stop the phpmyadmin-<phpmyadmin_version> cartridge
    Then a httpd process will not be running

    When I start the phpmyadmin-<phpmyadmin_version> cartridge
    Then a httpd process will be running

    When I restart the phpmyadmin-<phpmyadmin_version> cartridge
    Then a httpd process will be running

    When I destroy the application
    Then a httpd process will not be running

    @rhel-only
    Scenarios: RHEL
      | phpmyadmin_version | database  |
      |        3.4         | mysql-5.1 |

    @fedora-19-only
    Scenarios: Fedora 19
      | phpmyadmin_version | database    |
      |        3.5         | mariadb-5.5 |