@runtime_extended_other2
@runtime
@not-origin
Feature: HAProxy Application Sub-Cartridge

  Scenario Outline: Create Delete Application With haproxy Scenarios (RHEL/CentOS)
    #Given a new <cart_name> application, verify haproxy-1.4 using httpd process
    Given a new <cart_name> type application
    Then a <proc_name> process will be running

    When I embed a haproxy-1.4 cartridge into the application
    Then 0 process named haproxy will be running
    And the embedded haproxy-1.4 cartridge directory will exist
    And the haproxy configuration file will exist
    And the haproxy PATH override will exist

    When I destroy the application
    Then 0 processes named haproxy will be running
    And a <proc_name> process will not be running
    And the embedded haproxy-1.4 cartridge directory will not exist
    And the haproxy configuration file will not exist
    
    Scenario: RHEL compatible cartridges
      | cart_name  |
      | ruby-1.8   |
      | php-5.3    |
      | perl-5.10  |
      | python-2.6 |
      | ruby-1.8   |
      | nodejs-0.6 |
      | ruby-1.9   |

    @jboss
    Scenario: JBoss based cartridges
      | cart_name    |
      | jbossas-7    |
      | jbosseap-6.0 |