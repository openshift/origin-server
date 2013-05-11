@runtime
@runtime_extended_other2
Feature: Cartridge Runtime Extended Checks (Database)

  Scenario Outline: Embed and then remove database cartridges (Common)
    Given a <app_type> application, add and remove <db_cart_type> database and use <db_proc> proc and <db_name> name to verify
    Scenarios: Embed/Unembed database cartridge scenarios - origin
      | app_type  | db_cart_type    | db_proc   | db_name     |
      | ruby-1.9  | mongodb-2.2     | mongod    | mongodb     |

  @fedora-only
  Scenario Outline: Embed and then remove database cartridges (Fedora)
    Given a <app_type> application, add and remove <db_cart_type> database and use <db_proc> proc and <db_name> name to verify
    Scenarios: Embed/Unembed database cartridge scenarios
      | app_type  | db_cart_type    | db_proc   | db_name     |
      | php-5.4   | mysql-5.1       | mysqld    | mysql       |
      | php-5.4   | mongodb-2.2     | mongod    | mongodb     |
      | php-5.4   | postgresql-9.2  | postgres  | postgresql  |      

  @rhel-only
  Scenario Outline: Embed and then remove database cartridges (Fedora)
    Given a <app_type> application, add and remove <db_cart_type> database and use <db_proc> proc and <db_name> name to verify
    Scenarios: Embed/Unembed database cartridge scenarios
      | app_type  | db_cart_type    | db_proc   | db_name     |
      | php-5.3   | mysql-5.1       | mysqld    | mysql       |
      | php-5.3   | mongodb-2.2     | mongod    | mongodb     |
      | ruby-1.8  | mongodb-2.2     | mongod    | mongodb     |
      | php-5.3   | postgresql-8.4  | postgres  | postgresql  |      

  @rhel-only
  Scenario Outline: Embed all databases into one cartridges (RHEL/CentOS)
    Given a php-5.3 application, embed mysql-5.1, postgresql-8.4, mongodb-2.2

  @Fedora-only
  Scenario Outline: Embed all databases into one cartridges (Fedora)
    Given a php-5.4 application, embed mysql-5.1, postgresql-9.2, mongodb-2.2
