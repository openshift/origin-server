@not-enterprise
@cartridge_extended4

Feature: Cartridge Lifecycle JBoss Unified Push Server Verification Tests

  Scenario Outline: Application Creation

    Given the libra client tools
      #When 1 <cart_name> applications are created
      When I create a <cart_name> app

    Given an existing <cart_name> application
      Then the application should be accessible
      And a mysqld process will be running

      When the application is stopped
      Then the application should not be accessible
      And a mysqld process will not be running

      When the application is started
      Then the application should be accessible
      And a mysqld process will be running

      When I tidy the application
      Then the application should be accessible
      And a mysqld process will be running

      When the application is restarted
      Then the application should be accessible
      And a mysqld process will be running

      When the application is destroyed
      Then the application should not be accessible
      And a mysqld process will not be running

  Scenarios: RHEL scenarios
    | cart_name |
    | jboss-unified-push-2 |
