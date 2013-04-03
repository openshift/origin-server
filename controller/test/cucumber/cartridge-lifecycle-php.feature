#@runtime_other4
@runtime
@runtime4
@not-enterprise
Feature: Cartridge Lifecycle PHP Verification Tests
  @rhel-only
  Scenario: Application Creation (RHEL/CentOS)
    Given a new php-5.3 application, verify its availability
  
  @rhel-only
  Scenario: Server Alias (RHEL/CentOS)
    Given an existing php-5.3 application, verify application aliases

  @rhel-only
  Scenario: Application Submodule Addition (RHEL/CentOS)
    Given an existing php-5.3 application, verify submodules
    
  @rhel-only
  Scenario: Application Modification (RHEL/CentOS)
    Given an existing php-5.3 application, verify code updates
  
  @rhel-only
  Scenario: Application Stopping  (RHEL/CentOS)
    Given an existing php-5.3 application, verify it can be stopped
  
  @rhel-only
  Scenario: Application Starting  (RHEL/CentOS)
    Given an existing php-5.3 application, verify it can be started  
  
  @rhel-only
  Scenario: Application Restarting  (RHEL/CentOS)
    Given an existing php-5.3 application, verify it can be restarted
  
  @rhel-only
  Scenario: Application Tidy  (RHEL/CentOS)
    Given an existing php-5.3 application, verify it can be tidied
  
  @rhel-only
  Scenario: Application Snapshot  (RHEL/CentOS)
    Given an existing php-5.3 application, verify it can be snapshotted and restored
  
  @rhel-only
  Scenario: Application Change Namespace  (RHEL/CentOS)
    Given an existing php-5.3 application, verify its namespace cannot be changed
    
  @rhel-only
  Scenario: Application Destroying  (RHEL/CentOS)
    Given an existing php-5.3 application, verify it can be destroyed  
    
#######
    
  @fedora-only
  Scenario: Application Creation (RHEL/CentOS)
    Given a new php-5.4 application, verify its availability
  
  @fedora-only
  Scenario: Server Alias (RHEL/CentOS)
    Given an existing php-5.4 application, verify application aliases

  @fedora-only
  Scenario: Application Submodule Addition (RHEL/CentOS)
    Given an existing php-5.4 application, verify submodules
  
  @fedora-only
  Scenario: Application Modification (RHEL/CentOS)
    Given an existing php-5.4 application, verify code updates
  
  @fedora-only
  Scenario: Application Stopping  (RHEL/CentOS)
    Given an existing php-5.4 application, verify it can be stopped
  
  @fedora-only
  Scenario: Application Starting  (RHEL/CentOS)
    Given an existing php-5.4 application, verify it can be started  
  
  @fedora-only
  Scenario: Application Restarting  (RHEL/CentOS)
    Given an existing php-5.4 application, verify it can be restarted
  
  @fedora-only
  Scenario: Application Tidy  (RHEL/CentOS)
    Given an existing php-5.4 application, verify it can be tidied
  
  @fedora-only
  Scenario: Application Snapshot  (RHEL/CentOS)
    Given an existing php-5.4 application, verify it can be snapshotted and restored
  
  @fedora-only
  Scenario: Application Change Namespace  (RHEL/CentOS)
    Given an existing php-5.4 application, verify its namespace cannot be changed
  
  @fedora-only
  Scenario: Application Destroying  (RHEL/CentOS)
    Given an existing php-5.4 application, verify it can be destroyed
