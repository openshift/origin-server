#@runtime_other4
@runtime
@runtime3
Feature: Trap User Shell

  As a system designer
  I should be able to limit user login to a defined set of commands
  So that I can ensure the security of the system

  @rhel-only
  Scenario: Running commands via rhcsh (RHEL/CentOS)
    Given a new php-5.3 application, verify rhcsh
  
  @fedora-only
  Scenario: Running commands via rhcsh (Fedora)
    Given a new php-5.4 application, verify rhcsh

  @rhel-only
  Scenario: Tail Logs (RHEL/CentOS)
    Given a new php-5.3 application, verify tail logs
  
  @fedora-only  
  Scenario: Tail Logs (Fedora)
    Given a new php-5.4 application, verify tail logs
  
  @rhel-only
  Scenario: Access Quota (RHEL/CentOS)
    Given a new php-5.3 application, obtain disk quota information via SSH
    
#  @fedora-only
#  Scenario: Access Quota (Fedora)
#    Given a new php-5.4 application, obtain disk quota information via SSH
