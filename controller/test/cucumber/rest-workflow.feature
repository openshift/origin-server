@broker
Feature: Rest Quick tests
  As an developer I want to make sure I didn't break anything that is going to prevent others from working
  
  @fedora-only
  Scenario Outline: Typical Workflow
    Given a new user, verify typical REST interactios with a <php_version> application over <format> format
    
    Scenarios: Fedora 18
      | format | php_version |
      | JSON   |  php-5.4    |
      | XML    |  php-5.4    |
  
  @rhel-only
  Scenario Outline: Typical Workflow
    Given a new user, verify typical REST interactios with a <php_version> application over <format> format
    
    Scenarios: RHEL
      | format | php_version |
      | JSON   |  php-5.3    |
      | XML    |  php-5.3    |

