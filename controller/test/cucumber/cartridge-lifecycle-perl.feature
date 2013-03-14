@runtime_extended
@runtime_extended3
@runtime_extended_other3
Feature: Cartridge Lifecycle Perl Verification Tests
  @rhel-only
  Scenario: Application Creation (RHEL/CentOS)
    Given a new perl-5.10 application, verify its availability
  
  @rhel-only
  Scenario: Application Modification (RHEL/CentOS)
    Given an existing perl-5.10 application, verify code updates
  
  @rhel-only
  Scenario: Application Restarting  (RHEL/CentOS)
    Given an existing perl-5.10 application, verify it can be restarted
    
  @rhel-only
  Scenario: Application Destroying  (RHEL/CentOS)
    Given an existing perl-5.10 application, verify it can be destroyed  
    
#######
    
  @fedora-only
  Scenario: Application Creation (RHEL/CentOS)
    Given a new perl-5.16 application, verify its availability

  @fedora-only
  Scenario: Application Modification (RHEL/CentOS)
    Given an existing perl-5.16 application, verify code updates
    
  @fedora-only
  Scenario: Application Restarting  (RHEL/CentOS)
    Given an existing perl-5.16 application, verify it can be restarted
  
  @fedora-only
  Scenario: Application Destroying  (RHEL/CentOS)
    Given an existing perl-5.16 application, verify it can be destroyed
