@runtime_other1
@runtime
Feature: Application Repository

  Scenario: Verify git submodules support (RHEL/CentOS)
    Given a v2 default node
    Given a new php-5.3 application, verify its availability
    Given an existing php-5.3 application, verify submodules

