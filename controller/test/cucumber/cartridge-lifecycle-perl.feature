@cartridge_extended
@cartridge_extended3
Feature: Cartridge Lifecycle Perl Verification Tests
  Scenario Outline: Application Creation
  #Given a new <cart_name> application, verify its availability
    Given the libra client tools
    When 1 <cart_name> applications are created
    Then the applications should be accessible
    Then the applications should be accessible via node-web-proxy
    Given an existing <cart_name> application

  #Given an existing <cart_name> application, verify application aliases
  #  Given an existing <cart_name> application
  #  When the application is aliased
  #  Then the application should respond to the alias
  #
  #Given an existing <cart_name> application, verify submodules
  #  When the submodule is added
  #  Then the submodule should be deployed successfully
  #  And the application should be accessible

  #Given an existing <cart_name> application, verify code updates
    When the application is changed
    Then it should be updated successfully
    And the application should be accessible

  #Given an existing <cart_name> application, verify it can be stopped
  #  When the application is stopped
  #  Then the application should not be accessible
  #
  #Given an existing <cart_name> application, verify it can be started
  #  When the application is started
  #  Then the application should be accessible
  #
  #Given an existing <cart_name> application, verify it can be tidied
  #  When I tidy the application
  #  Then the application should be accessible

  #Given an existing <cart_name> application, verify it can be restarted
    When the application is restarted
    Then the application should be accessible

  #Given an existing <cart_name> application, verify it can be destroyed
    When the application is destroyed
    Then the application should not be accessible
    Then the application should not be accessible via node-web-proxy

    Scenarios: RHEL scenarios
      | cart_name |
      | perl-5.10 |


  Scenario Outline: Application backward compatibility
    #Given a new <cart_name> application, verify its availability
    Given the libra client tools
    When 1 <cart_name> applications are created
    Then the applications should be accessible
    Then the applications should be accessible via node-web-proxy
    Given an existing <cart_name> application

    #Given an existing <cart_name> application, change DocumentRoot to backward compatible /perl directory
    When the application document root is changed to perl/ directory
    Then it should be updated successfully
    And the application should be accessible

    #Given an existing <cart_name> application, change DocumentRoot back to default directory
    When the application document root is changed from perl/ directory back to default directory
    Then it should be updated successfully
    And the application should be accessible

    #Given an existing <cart_name> application, verify it can be destroyed
    When the application is destroyed
    Then the application should not be accessible
    Then the application should not be accessible via node-web-proxy

    Scenarios: RHEL scenarios
      | cart_name |
      | perl-5.10 |


  Scenario Outline: Application with cpanfile
    Given the libra client tools
    When 1 <cart_name> applications are created
    Then the applications should be accessible
    Given an existing <cart_name> application

    When a cpanfile is added into repo directory
    Then the applications should be accessible

    Scenarios: RHEL scenarios
      | cart_name |
      | perl-5.10 |


  Scenario Outline: Application with Makefile.PL
    Given the libra client tools
    When 1 <cart_name> applications are created
    Then the applications should be accessible
    Given an existing <cart_name> application

    When a Makefile is added into repo directory
    Then the applications should be accessible

    Scenarios: RHEL scenarios
      | cart_name |
      | perl-5.10 |