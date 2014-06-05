@cartridge_extended4
@node
Feature: Cartridge Lifecycle PHP Verification Tests
  Scenario Outline: Application Creation
  #Given a new <cart_name> application, verify its availability
    Given the libra client tools
    When 1 <cart_name> applications are created
    Then the applications should be accessible
    Then the applications should be accessible via node-web-proxy

  #Given an existing <cart_name> application, verify application aliases
    Given an existing <cart_name> application
    When the application is aliased
    Then the application should respond to the alias

  #Given an existing <cart_name> application, verify standard module "gd" is available
    And the php module gd will be loaded

  #Given an existing <cart_name> application, verify code updates
    When the application is changed
    Then it should be updated successfully
    And the application should be accessible

  #Given an existing <cart_name> application, verify
  #Apache DocumentRoot and dirs/files Access Controls

  # Apache DocumentRoot is selected based on the existence of a common
  # public directory in the application code in the following order:
  # 1. php/          # for backward compatibility with OpenShift Origin v1/v2
  # 2. public/       # Zend Framework v1/v2, Laravel, FuelPHP, Surebert etc.
  # 3. public_html/  # Apache per-user web directories, Slim Framework etc.
  # 4. web/          # Symfony etc.
  # 5. www/          # Nette etc.
  # 6. ./            # Drupal, Wordpress, CakePHP, CodeIgniter, Joomla, Kohana, PIP etc.

  # 6. ./
    When I remove all files from repo directory
    And I create root.php file in the ./ repo directory
    Then the root.php url should be accessible
    And the .openshift/ deplist.txt urls should not be accessible

  # 5. www/, ./
    When I create www.php file in the www/ repo directory
    Then the www.php url should be accessible

  # 4. web/, www/, ./
    When I create web.php file in the web/ repo directory
    Then the web.php url should be accessible

  # 3. public_html/, web/, www/, ./
    When I create public_html.php file in the public_html/ repo directory
    Then the public_html.php url should be accessible

  # 2. public/, public_html/, web/, www/, ./
    When I create public.php file in the public/ repo directory
    Then the public.php url should be accessible

  # 1. php/, public/, public_html/, web/, www/, ./
    When I create php.php file in the php/ repo directory
    Then the php.php url should be accessible

  # 0. repo cleanup
    When I remove all files from repo directory
    And I create index.php file in the ./ repo directory
    Then the application should be accessible

  #Set up dynamic PHP module test
    When a new environment variable key=OPENSHIFT_PHP_GD_ENABLED value=false is added

  #Given an existing <cart_name> application, verify it can be stopped
    When the application is stopped
    Then the application should not be accessible

  #Given an existing <cart_name> application, verify it can be started
    When the application is started
    Then the application should be accessible

  #Verify PHP module "gd" is disabled after stop/start by user env var
  # OPENSHIFT_PHP_GD_ENABLED=false
    Then the php module gd will not be loaded

  #Given an existing <cart_name> application, verify it can be tidied
    When I tidy the application
    Then the application should be accessible

  #Given an existing <cart_name> application, verify it can be restarted
    When the application is restarted
    Then the application should be accessible

  #Given an existing <cart_name> application, verify it can be destroyed
    When the application is destroyed
    Then the application should not be accessible
    Then the application should not be accessible via node-web-proxy

  Scenarios: RHEL scenarios
    | cart_name |
    | php-5.3   |
    | php-5.4   |
