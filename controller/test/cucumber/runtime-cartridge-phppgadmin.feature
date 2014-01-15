@runtime_extended3
@not-enterprise
Feature: phpPgAdmin Embedded Cartridge

  @rhel-only
  Scenario Outline: Add Remove phpPgAdmin to one application
    Given a new mock-0.1 type application

    When I embed a <database> cartridge into the application
    And I embed a phppgadmin-<phppgadmin_version> cartridge into the application
    Then a httpd process will be running
    And the phppgadmin-<phppgadmin_version> cartridge instance directory will exist

    When I stop the phppgadmin-<phppgadmin_version> cartridge
    Then a httpd process will not be running

    When I start the phppgadmin-<phppgadmin_version> cartridge
    Then a httpd process will be running

    When I restart the phppgadmin-<phppgadmin_version> cartridge
    Then a httpd process will be running

    When I destroy the application
    Then a httpd process will not be running

    @rhel-only
    Scenarios: RHEL
      | phppgadmin_version | database       |
      |        5.0         | postgresql-8.4 |
      |        5.0         | postgresql-9.2 |

    @fedora-19-only
    Scenarios: Fedora 19
      | phppgadmin_version | database       |
      |        5.0         | postgresql-9.2 |
