@runtime
@runtime_extended_other2
Feature: PHP Application
  @rhel-only
  Scenario: Test Alias Hooks (RHEL/CentOS)
    Given a new php-5.3 application, verify application alias setup on the node

  @rhel-only
  Scenario Outline: PHP cartridge checks
    Given a new php-5.3 application, verify it using httpd
    
  @fedora-only
  Scenario Outline: PHP cartridge checks
    Given a new php-5.4 application, verify it using httpd

  @rhel-only
  Scenario Outline: Hot deployment tests (RHEL/CentOS)
    Given a new php-5.3 application, verify when hot deploy <hot_deploy_status>, it <pid_changed> pid of httpd proc    
    Scenarios: Code push scenarios
      | hot_deploy_status | pid_changed     |
      | is enabled        | does not change |
      | is not enabled    | does change     |

  @fedora-only
  Scenario Outline: Hot deployment tests (RHEL/CentOS)
    Given a new php-5.4 application, verify when hot deploy <hot_deploy_status>, it <pid_changed> pid of httpd proc    
    Scenarios: Code push scenarios
      | hot_deploy_status | pid_changed     |
      | is enabled        | does not change |
      | is not enabled    | does change     |
