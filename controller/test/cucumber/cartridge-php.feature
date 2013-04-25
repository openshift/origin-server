#@runtime_other4
@runtime
@runtime2
Feature: PHP Application
  @rhel-only
  Scenario: Test Alias Hooks (RHEL/CentOS)
    Given a new php-5.3 application, verify application alias setup on the node
    
# @fedora-only
# Scenario: Test Alias Hooks (Fedora)
#   Given a new php-5.4 application, verify application alias setup on the node
