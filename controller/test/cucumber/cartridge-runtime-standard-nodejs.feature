@runtime
@rhel-only
@not-enterprise
Feature: Cartridge Runtime Standard Checks (Node)

  @runtime1
  Scenario: Node cartridge checks
    Given a new nodejs-0.6 application, verify it using node
