@runtime
@rhel-only
@not-enterprise
Feature: Cartridge Runtime Standard Checks (Node)

  #@runtime_other4
  @runtime_extended1
  Scenario: Node cartridge checks
    Given a new nodejs-0.6 application, verify it using node
