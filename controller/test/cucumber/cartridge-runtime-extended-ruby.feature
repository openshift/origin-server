#@runtime_extended2
@runtime_extended_other2
@runtime
Feature: Cartridge Runtime Extended Checks (Ruby)

  @rhel-only
  Scenario Outline: Hot deployment tests (RHEL/CentOS)
    Given a new ruby-1.8 application, verify when hot deploy <hot_deploy_status>, it <pid_changed> pid of PassengerWatchd proc    
    Scenarios: Code push scenarios
      | hot_deploy_status | pid_changed     |
      | is enabled        | does not change |
      | is not enabled    | does change     |

  Scenario Outline: Hot deployment tests (RHEL/CentOS)
    Given a new ruby-1.9 application, verify when hot deploy <hot_deploy_status>, it <pid_changed> pid of PassengerWatchd proc    
    Scenarios: Code push scenarios
      | hot_deploy_status | pid_changed     |
      | is enabled        | does not change |
      | is not enabled    | does change     |
