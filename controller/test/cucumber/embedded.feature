#@runtime_extended_other3
@runtime_extended
@runtime_extended3
Feature: Embedded Cartridge Verification Tests
  @rhel-only
  Scenario Outline: Embedded Usage (RHEL/CentOS)
  Given the libra client tools, create a new php-<php_version> application, verify addition and removal of mysql-5.1 , phpmyadmin-<phpmyadmin_version> , cron-1.4 , mongodb-2.2

    Scenarios: RHEL scenarios
      | php_version | phpmyadmin_version |
      |     5.3     |            3.4     |

  @fedora-only
  Scenario Outline: Embedded Usage (Fedora)
  Given the libra client tools, create a new php-<php_version> application, verify addition and removal of mysql-5.1 , phpmyadmin-<phpmyadmin_version> , cron-1.4 , mongodb-2.2  
  
    Scenarios: Fedora 18 scenarios
      | php_version | phpmyadmin_version |
      |     5.4     |            3.5     |