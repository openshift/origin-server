@cartridge_extended
@cartridge_extended4
Feature: Cartridge Lifecycle Python Verification Tests
  Scenario Outline: Application Creation
  #Given a new <cart_name> application, verify its availability
    Given the libra client tools
    When 1 <cart_name> applications are created
    Then the applications should be accessible
    Then the applications should be accessible via node-web-proxy
    Given an existing <cart_name> application

  #Given an existing <cart_name> application, verify code updates
    When the application is changed
    Then it should be updated successfully
    And the application should be accessible

  #Given an existing <cart_name> application, verify it can be restarted
    When the application is restarted
    Then the application should be accessible

  #Given an existing <cart_name> application, verify WSGI entry-point
    # wsgi/application (backward compatibility with old Python template repo)
    When I rename wsgi.py repo file as wsgi/application file
    Then the application should be accessible

    # custom WSGI file (user sets ENV VAR)
    When a new environment variable key=OPENSHIFT_PYTHON_WSGI_APPLICATION value=some/other/dir/wsgi.py is added
    And I rename wsgi/application repo file as some/other/dir/wsgi.py file
    Then the application should be accessible

  #Given an existing <cart_name> application, verify it can be destroyed
    When the application is destroyed
    Then the application should not be accessible
    Then the application should not be accessible via node-web-proxy

  Scenarios: RHEL scenarios
    | cart_name  |
    | python-2.6 |
    | python-2.7 |
    | python-3.3 |
