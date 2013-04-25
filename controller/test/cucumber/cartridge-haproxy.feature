#@runtime_other4
@runtime
@runtime3
Feature: HAProxy Application Sub-Cartridge
  @rhel-only
  Scenario Outline: Create Delete Application With haproxy Scenarios (RHEL/CentOS)
    Given a new <cart_name> application, verify haproxy-1.4 using httpd process
    
    Scenario: RHEL compatible cartridges
      | cart_name  |
      | ruby-1.8   |
      | php-5.3    |
      | perl-5.10  |
      | python-2.6 |
      | ruby-1.8   |
    
  @jboss
  Scenario Outline: Create Delete Application With haproxy Scenarios (JBoss)
    Given a new <cart_name> application, verify haproxy-1.4 using java process
    
    Scenario: JBoss based cartridges
      | cart_name    |
      | jbossas-7    |
      | jbosseap-6.0 |
    
  @fedora-only
  Scenario Outline: Create Delete Application With haproxy Scenarios (Fedora)
    Given a new <cart_name> application, verify haproxy-1.4 using httpd process
    
    Scenario: Fedora compatible cartridges
      | cart_name  |
      | php-5.4    |
      | perl-5.16  |

  Scenario Outline: Create Delete Application With haproxy Scenarios (Common)
    Given a new <cart_name> application, verify haproxy-1.4 using httpd process
    
    Scenario: Common cartridges
      | cart_name  |
      | nodejs-0.6 |
      | ruby-1.9   |
