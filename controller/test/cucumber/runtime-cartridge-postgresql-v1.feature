Feature: PostgreSQL Application Sub-Cartridge
  @runtime_extended_other2
  @runtime
  @postgres
  @rhel-only
  Scenario: Create Delete one application with a PostgreSQL database
    Given a perl-5.10 application, verify addition and removal of postgresql 8.4

  @runtime_extended_other2
  @runtime
  @postgres
  @fedora-only
  Scenario: Create Delete one application with a PostgreSQL database
    Given a perl-5.16 application, verify addition and removal of postgresql 9.2

  @runtime_extended_other3
  @postgres
  Scenario Outline: Use socket file to connect to database
    Given a new <php_version> type application
    And I embed a <postgres_cart> cartridge into the application
    And the application is made publicly accessible

    Given I use socket to connect to the postgresql database as env with password
    Then I should be able to query the postgresql database

    @rhel-only
    Scenarios: database cartridge scenarios
      | postgres_cart  | php_version |
      | postgresql-8.4 | php-5.3     |

