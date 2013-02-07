@runtime
@runtime3
Feature: Trap User Shell

  As a system designer
  I should be able to limit user login to a defined set of commands
  So that I can ensure the security of the system

  Scenario Outline: Running commands via rhcsh
    Given a new <php_version> type application
    And the application is made publicly accessible

    Then I can run "ls / > /dev/null" with exit code: 0
    And I can run "this_should_fail" with exit code: 127
    And I can run "true" with exit code: 0
    And I can run "java -version" with exit code: 0
    And I can run "scp" with exit code: 1

    @fedora-only
    Scenarios: Fedora 18
     | php_version |
     |  php-5.4    |

    @rhel-only
    Scenarios: RHEL
     | php_version |
     |  php-5.3    |

  Scenario Outline: Tail Logs
    Given a new <php_version> type application
    And the application is made publicly accessible
    Then a tail process will not be running

    When I tail the logs via ssh
    Then a tail process will be running

    When I stop tailing the logs
    Then a tail process will not be running

    @fedora-only
    Scenarios: Fedora 18
     | php_version |
     |  php-5.4    |
     
    @rhel-only
    Scenarios: RHEL
     | php_version |
     |  php-5.3    |

  Scenario Outline: Access Quota
    Given a new <php_version> type application
    And the application is made publicly accessible
    Then I can obtain disk quota information via SSH

    @fedora-only
    Scenarios: Fedora 18
     | php_version |
     |  php-5.4    |
     
    @rhel-only
    Scenarios: RHEL
     | php_version |
     |  php-5.3    |
